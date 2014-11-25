minimist = require 'minimist'

argv = minimist(process.argv)

conf =
  input: argv.input
  ip: argv.ip
  mode: argv.mode
  help: argv.help
  port: argv['port'] || 8123

help = """
  mincast --input path.to.file.mkv \
    --ip [ip of your machine] \
    --port [http port to use] \
    --mode [original|stream-transcode|transcode] \
    --cli-controller
    """

if conf.help then return console.log help

ChromecastWrapper = require './chromecast_wrapper'
chromecastWrapper = new ChromecastWrapper(conf.ip, conf.port)

HttpServer = require './http_server'
httpServer = new HttpServer conf.input, conf.port, conf.mode

if conf['cli-controller']
  Remotecontroller = require './remote_controller'
  delayed = -> new RemoteController(chromecastWrapper)
  setTimeout delayed, 1000
