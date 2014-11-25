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
    ext = req.path.split('.').pop()
    if ext == 'vtt'
      res.contentType(ext)
      return @handleSubtitles req, res, next
    if @mode == 'original'
      return res.sendFile(@input)
    if @mode == 'stream-transcode'
      return @handleMediaStreamTranscode req, res, next
  handleSubtitles: (req, res, next) ->
    tryWith = (ext) =>
      subtitles = @input.split('.')
      subtitles.pop()
      subtitles.push ext
      subtitles = subtitles.join '.'
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
    res.status(206)
    ff = ffmpeg(@input, {})
    ff.inputOptions('-fix_sub_duration')
    ff.videoCodec('copy')
    ff.audioCodec('libfaac').audioBitrate('320k')
    ff.toFormat("matroska")
    ff.pipe(res, end: true)
    ff.on 'start', (command) -> console.log command
    ff.on 'error', (err) -> console.error err

module.exports = HttpServer
