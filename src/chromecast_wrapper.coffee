chromecastjs = require 'chromecast-js'
ips = require './ips'

class ChromecastWrapper
  constructor: (ip, port) ->
    @device = null
    @connected = false
    @volume = 1.0
    @statusLast = null
    @ip = ip || false
    @port = port
    @browser = new chromecastjs.Browser()
    console.log 'Looking for Chromecast devices around..'
    @browser.on 'deviceOn', @deviceOn.bind(@)
  mediaDescriptionGet: () ->
    # if we don't have an ip, pick the first candidate
    # based on chromecast device host ip
    ip = @ip || ips.candidates(@device.host).pop()
    port = @port
    media =
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
    return media
  deviceOn: (device) ->
    console.log 'This device is on ', device.host
    @device = device
    @device.on 'connected', @deviceConnected.bind(@)
    @device.connect()
  deviceConnected: () ->
    @connected = true
    console.log 'Chromecast connected'
    @play()
  play: (offset) =>
    offset = offset || 0
    if not @connected
      return console.log 'we are not connected'
    if @locked then return console.log 'skipping play request'
    media = @mediaDescriptionGet()
    console.log 'Going to play', media.url
    @device.play media, offset, @playDone.bind(@)
    @locked = true
  playDone: ->
    console.log 'play', arguments[0]
    @locked = false
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
    @device.seek amount, (err, status) ->
      if err then return console.error err
      console.log 'seek ', amount, status.currentTime
  volumeSet: =>
    if not @connected then return console.log 'we are not connected'
    arg =
      level: @volume
    @device.setVolume @volume, (err, res) ->
      console.log 'volume set', res.level
  volumeUp: =>
    if not @connected then return console.log 'we are not connected'
    @volume += 0.1
    @volumeSet()
  volumeDown: =>
    if not @connected then return console.log 'we are not connected'
    @volume -= 0.1
    @volumeSet()
  getStatus: (cb) =>
    onStatus = (status) ->
      # sometimes device returns a null status, in that case we use the last
      # known one
      if not status
        status = @statusLast
      else
        @statusLast = status
      cb(status)
    if not @device then return cb(null)
    if not @device.getStatus then return cb(null)
    if not @connected then return cb(null)
    @device.getStatus(onStatus.bind(@))

module.exports = ChromecastWrapper
