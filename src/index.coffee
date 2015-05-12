minimist = require 'minimist'
ChromecastWrapper = require './chromecast_wrapper'
HttpServer = require './http_server'
RemoteController = require './remote_controller'
FFMpegRegistry = require './ffmpeg_registry'

argv = minimist(process.argv)

conf =
  input: argv.input
  ip: argv.ip || false
  mode: argv.mode
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
    @httpServer = new HttpServer conf.input, conf.port, conf.mode, conf.verbose
    if conf.mode == 'transcode'
      @httpServer.mode = 'stream-transcode'
      @mediaTranscode()

    if conf.cli_controller
      delayed = -> new RemoteController(@chromecastWrapper, @)
      setTimeout delayed.bind(@), 1000

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


  
