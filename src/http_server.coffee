logger = require 'morgan'
express = require 'express'
serveStatic = require 'serve-static'
fs = require 'fs'
srt2vtt = require 'srt2vtt'
ffmpeg = require 'fluent-ffmpeg'
process.env.PATH += ":/usr/local/bin"

allowCrossDomain = (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', '*'
  res.header 'Access-Control-Expose-Headers', 'Content-Type, Range, Accept-Encoding'
  res.header 'Access-Control-Allow-Headers', 'Content-Type, Range, Accept-Encoding'
  res.header 'Access-Control-Max-Age', 60 * 60 * 24 * 365
  if req.method == 'OPTIONS'
    return res.send(200)
  next()

class HttpServer
  constructor: (@input, @port, @mode) ->
    app = express()
    app.use allowCrossDomain
    app.use logger()
    app.use @handle.bind(@)
    app.listen @port
  handle: (req, res, next) ->
    console.log 'headers', req.headers
    ext = req.path.split('.').pop()
    if ext == 'vtt'
      res.contentType(ext)
      return @handleSubtitles req, res, next
    if @mode == 'original'
      return res.sendFile(@input)
    if @mode == 'stream-transcode'
      return @handleMediaStreamTranscode req, res, next
  handleSubtitles: (req, res, next) ->
    console.log 'I should serve the vtt file'
    tryWith = (ext) =>
      subtitles = @input.split('.')
      subtitles.pop()
      subtitles.push ext
      subtitles = subtitles.join '.'
      console.log subtitles
      return subtitles
    ext = 'srt'
    subtitles = tryWith ext
    src = subtitles
    fs.stat src, (err) ->
      if err
        res.end "no subs", 404
        return
      srt = fs.readFileSync src
      srt2vtt srt, (err, vtt) ->
        res.status 200
        res.contentType ext
        res.send vtt
  handleMediaStreamTranscode: (req, res, next) ->
    res.header 'Accept-Ranges', 'bytes'
    ffmpeg.ffprobe @input, (err, meta) =>
      if err then return console.log(err)
      range = req.header 'range'
      range = range || "bytes=0-"
      range = range.split('=')[1]
      range_start = range.split('-')[0]
      console.log 'range start', range_start
      original_size = meta.format.size
      original_duration = meta.format.duration
      console.log 'original size', original_size
      console.log 'original duration', original_duration
      
      original_size = parseInt original_size
      range_start = parseInt range_start
      res.header 'Content-Range', 'bytes ' + range_start + '-' + (original_size - 1) + '/' + original_size
      res.header 'Content-Length', (original_size - range_start)
      res.header 'Cache-Control', 'public, max-age=0'

      percent = range_start / original_size || 0
      console.log 'start from percent', percent
      time_offset = original_duration * percent || 0
      console.log 'start from time offset', time_offset

      # we are serving the video
      res.status(206)

      ff = ffmpeg(@input, {})
      ff.inputOptions('-fix_sub_duration')
      if time_offset != 0
        ff.seek time_offset
      ff.videoCodec('copy')
      ff.audioCodec('libfaac').audioBitrate('320k')
      ff.toFormat("matroska")
      ff.pipe(res, end: true)
        
      res.on 'close', -> console.log 'RESPONSE CLOSED'
      res.on 'end', -> console.log 'RESPONSE ENDED'
      ff.on 'start', (command) -> console.log command
      ff.on 'error', (log) -> console.log log

module.exports = HttpServer
