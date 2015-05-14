ipc = require('ipc')

class UIManager
  constructor: (@player, @manager) ->
    @mainWindow = null
    @app = require 'app'
    @BrowserWindow = require('browser-window')
    @crashReporter = require('crash-reporter')
    @crashReporter.start()
    @app.on('window-all-closed', @windowsClosed.bind(@))
    @app.on('ready', @ready.bind(@))
    ipc.on('invoke', @invoke.bind(@))
  ready: ->
    opts =
      width: 450
      height: 135
    @mainWindow = new @BrowserWindow(opts)
    @mainWindow.loadUrl('file://' + __dirname + '/../ui/index.html')
    @mainWindow.on('closed', @mainWindowClosed.bind(@))
    setTimeout(@statusEmitter.bind(@), 2000)
  mainWindowClosed: -> @mainWindow = null

  statusEmitter: ->
    @manager.statusGet(@statusEmitterOnStatus.bind(@))
  statusEmitterOnStatus: (status) ->
    if @mainWindow.webContents and @mainWindow.webContents.send
      @mainWindow.webContents.send('status', status)
    setTimeout(@statusEmitter.bind(@), 2000)

  invoke: (e, methodName, arg1, arg2) ->
    try
      method = @[methodName]
      method = method.bind(@)
      method(arg1, arg2)
    catch e
      console.log('invoke exception', e)
  inputSet: (input) ->
    console.log('setting path to', input)
    @manager.httpServer.input = input
    @manager.chromecastWrapper.play()
  play: -> @player.play()
  pause: -> @player.pause()
  unpause: -> @player.unpause()
  pauseToggle: -> @player.pauseToggle()
  seek: (amount) -> @manager.seek(amount)
  stop: -> @player.stop()
  quit: -> @manager.quit()
  windowsClosed: -> @app.quit()

module.exports = UIManager
