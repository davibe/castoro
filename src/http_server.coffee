logger = require 'morgan'
express = require 'express'
serveStatic = require 'serve-static'
fs = require 'fs'
srt2vtt = require 'srt2vtt'
vttTimeTravel = require('./vtt_time_travel')
FFMpegRegistry = require './ffmpeg_registry'

allowCrossDomain = (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', '*'
  res.header 'Access-Control-Expose-Headers', 'Content-Type, Range, Accept-Encoding'
  res.header 'Access-Control-Allow-Headers', 'Content-Type, Range, Accept-Encoding'
  res.header 'Access-Control-Max-Age', 60 * 60 * 24 * 365
  if req.method == 'OPTIONS'
    return res.send(200)
  next()

class HttpServer
  constructor: (@input, @port, @mode, verbose) ->
    app = express()
    app.use allowCrossDomain
    if verbose then app.use logger()
    app.use @handle.bind(@)
    app.listen @port
    @mediaOffset = 0 # seconds, float
  mediaOffsetSet: (offset) ->
    @mediaOffset = offset
  handle: (req, res, next) ->
    ext = req.path.split('.').pop()
    if ext == 'vtt'
      res.contentType(ext)
      return @handleSubtitles req, res, next
    if @mode == 'original'
      return res.sendFile(@input)
    if @mode == 'stream-transcode'
      return @handleMediaStreamTranscode req, res, next
    if @mode == 'transcode'
      return res.sendFile('/tmp/target.mkv', @mediaOffset)
  handleSubtitles: (req, res, next) ->
    tryWith = (ext) =>
      subtitles = @input.split('.')
      subtitles.pop()
      subtitles.push(ext)
      subtitles = subtitles.join('.')
      return subtitles
    ext = 'srt'
    subtitles = tryWith ext
    src = subtitles
    self = @
    fs.stat src, (err) ->
      if err
        res.end "no subs", 404
        return
      srt = fs.readFileSync src
      srt2vtt srt, (err, vtt) ->
        res.status 200
        res.contentType ext
        vtt = vttTimeTravel(vtt, self.mediaOffset)
        res.send vtt
  handleMediaStreamTranscode: (req, res, next) ->
    ff = FFMpegRegistry.get(@input, {})
    ff.inputOptions('-fix_sub_duration')
    ff.inputOptions('-strict -2')
    ff.videoCodec('copy')
    ff.audioFilters('volume=2.0')
    ff.audioCodec('aac').audioBitrate('320k')
    ff.toFormat("matroska")
    if @mediaOffset
      ff.seek(@mediaOffset)
    ff.pipe(res, end: true)
    ff.on 'start', (command) -> console.log "Launching ffmpeg: ", command
    ff.on 'error', (err) -> console.error err

module.exports = HttpServer
