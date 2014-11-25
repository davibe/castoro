chromecastjs = require 'chromecast-js'

class ChromecastWrapper
  constructor: (ip, port) ->
    @browser = new chromecastjs.Browser()
    @device = null
    @connected = false
    @browser.on 'deviceOn', @deviceOn.bind(@)
    @volume = 1.0
    @media =
      url: "http://#{ip}:#{port}/target.mkv" # "http://commondatastorage.googleapis.com/gtv-videos-bucket/big_buck_bunny_1080p.mp4" #@uri
      subtitles: [
        language: 'en-US',
        url: "http://#{ip}:#{port}/target.vtt"
        name: 'subtitle'
      ]
      subtitles_style:
        backgroundColor: '#00000000'# see http://dev.w3.org/csswg/css-color/#hex-notation
        foregroundColor: '#000000' # see http://dev.w3.org/csswg/css-color/#hex-notation
        edgeType: 'OUTLINE' # can be: "NONE", "OUTLINE", "DROP_SHADOW", "RAISED", "DEPRESSED"
        edgeColor: '#000000' # see http://dev.w3.org/csswg/css-color/#hex-notation
        fontScale: 1.0 # transforms into "font-size: " + (fontScale*100) +"%"
        fontStyle: 'NORMAL' # can be: "NORMAL", "BOLD", "BOLD_ITALIC", "ITALIC",
        fontFamily: 'Droid Sans'
        fontGenericFamily: 'CURSIVE' # can be: "SANS_SERIF", "MONOSPACED_SANS_SERIF", "SERIF", "MONOSPACED_SERIF", "CASUAL", "CURSIVE", "SMALL_CAPITALS",
        windowColor: '#00000000' # see http://dev.w3.org/csswg/css-color/#hex-notation
        windowRoundedCornerRadius: 10 # radius in px
        windowType: 'NONE' # can be: "NONE", "NORMAL", "ROUNDED_CORNERS"
  deviceOn: (device) ->
    console.log 'This device is on', device
    @device = device
    @device.on 'connected', @deviceConnected.bind(@)
    @device.connect()
  deviceConnected: () ->
    @connected = true
    console.log 'Chromecast connected'
    @play()

  play: (offset) =>
    offset = offset || 1
    if not @connected
      return console.log 'we are not connected'
    console.log 'Going to play', @media
    @device.play @media, offset, -> console.log 'play', arguments[0]
  pause: =>
    if not @connected then return console.log 'we are not connected'
    @device.pause -> console.log 'pause', arguments
  unpause: =>
    if not @connected then return console.log 'we are not connected'
    @device.unpause -> console.log 'unpause', arguments
  pauseToggle: =>
    @getStatus (status) =>
      if (status.playerState == 'PLAYING') then @pause()
      if (status.playerState == 'PAUSED') then @unpause()
  seek: (amount) =>
    if not @connected then return console.log 'we are not connected'
    @device.seek amount, -> console.log 'seek', arguments
  volumeSet: =>
    if not @connected then return console.log 'we are not connected'
    arg =
      level: @volume
    @device.setVolume @volume, -> console.log 'volume set', arguments
  volumeUp: =>
    if not @connected then return console.log 'we are not connected'
    @volume += 0.1
    @volumeSet()
  volumeDown: =>
    if not @connected then return console.log 'we are not connected'
    @volume -= 0.1
    @volumeSet()
  getStatus: (cb) =>
    try
      @device.getStatus cb
    catch e
      cb {}
  quit: =>
    if @ff
      cast.ff.kill()

module.exports = ChromecastWrapper
