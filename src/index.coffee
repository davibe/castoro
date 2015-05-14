minimist = require 'minimist'
ChromecastWrapper = require './chromecast_wrapper'
HttpServer = require './http_server'
CliController = require './cli_controller'
FFMpegRegistry = require './ffmpeg_registry'

argv = minimist(process.argv)

conf =
  input: argv.input
  ip: argv.ip || false
  mode: argv.mode || 'stream-transcode'
  help: argv.help
  port: argv['port'] || 8123
  cli_controller: argv['cli-controller']
  verbose: argv.verbose

help = """
  castoro --input path.to.file.mkv \\
    --mode [original|stream-transcode|transcode]

  Other optional arguments:
    --ip [ip of your machine] # chromecast will connect to this ip
    --port [http port to use] # chromecast will connect to this port
    --cli-controller # control playback with keyboard keys
    --verbose
    """

if conf.help then return console.log help

class Manager
  constructor: (conf) ->
    @conf = conf
    @chromecastWrapper = new ChromecastWrapper(conf.ip, conf.port)
    @httpServer = new HttpServer(conf.input, conf.port, conf.mode, conf.verbose)

    if conf.mode == 'transcode'
      # strategy is to show live-transcoded version while we quickly transcode
      # the entyre media. As soon as the full transcode is complete we resume
      # the playback using the transcoded file and keeping plaback position
      # (switchToTranscoded fn)
      @httpServer.mode = 'stream-transcode'
      @mediaTranscode()

    if conf.cli_controller
      delayed = -> new CliController(@chromecastWrapper, @)
      setTimeout(delayed.bind(@), 1000)

    # activate ui if possible (if running inside electron.app.io)
    @uiManager = null
    try
      BrowserWindow = require('browser-window')
      if (BrowserWindow)
        UIController = require('./ui_controller')
        @uiController = new UIController(@chromecastWrapper, @)
    catch e

  mediaTranscode: ->
    conf = @conf
    ff = FFMpegRegistry.get(conf.input, {})
    ff.inputOptions('-fix_sub_duration')
    ff.inputOptions('-threads 16')
    ff.videoCodec('copy')
    ff.audioCodec('libfaac').audioBitrate('320k')
    ff.toFormat("matroska")
    ff.output('/tmp/target.mkv')
    ff.on('end', @switchToTranscoded.bind(@))
    ff.on('start', (command) -> console.log "Launching transcode: ", command)
    ff.on('progress', (progress) -> console.log 'Transcoding progress', progress.percent )
    ff.run()

  switchToTranscoded: ->
    self = @
    @chromecastWrapper.getStatus (status) ->
      console.log 'Switching to transcoded file'
      @httpServer.mode = 'transcode'
      self.chromecastWrapper.play status.currentTime

  statusGet: (cb) ->
    onStatus = (status) -> @statusGetOnStatus(status, cb)
    @chromecastWrapper.getStatus(onStatus.bind(@))

  statusGetOnStatus: (status, cb) ->
    status = status || {}
    if status.currentTime
      status.currentTime += (@httpServer.mediaOffset || 0)
    cb(status)

  seek: (amount) ->
    onStatus = (status) ->
      amount = amount + status.currentTime + @httpServer.mediaOffset
      console.log('seeking to', amount)
      @httpServer.mediaOffsetSet(amount)
      @chromecastWrapper.play()
    @chromecastWrapper.getStatus(onStatus.bind(@))

  quit: ->
    if @chromecastWrapper.device
      @chromecastWrapper.device.close()
    FFMpegRegistry.killAll()
    setTimeout process.exit.bind(process), 1000
    


manager = new Manager(conf)


  
