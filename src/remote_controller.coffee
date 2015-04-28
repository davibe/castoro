class RemoteController
  constructor: (@player, @manager) ->
    if process.stdin and process.stdin.setRawMode
      keypress = require 'keypress'
      keypress process.stdin
      process.stdin.setRawMode true
      process.stdin.resume()
      process.stdin.on 'keypress', @keypress.bind(@)
  
  keypress: (ch, key) ->
      console.log 'keypress', key.name
      if key.name == 'a'
        @player.unpause()
      if key.name == 'z'
        @player.pause()
      if key.name == 'space'
        @player.pauseToggle()
      if key.name == 'up'
        @player.volumeUp()
      if key.name == 'down'
        @player.volumeDown()
      if key.name == 't'
        @player.transcode()
      if key.name == 'p'
        @player.play()
      if key.name == 's'
        @player.getStatus (status) ->
          console.log 'status', status
      seekAmount = 60 * 10 # 10 minutes
      if key.name == 'right'
        if key.shift
          seekAmount /= 10 # 1 minute
        @manager.seek seekAmount
      if key.name == 'left'
        if key.shift
          seekAmount /= 10
        @manager.seek -1 * seekAmount
      if key.name == 'q' or key.name == 'c'
        @manager.quit()

module.exports = RemoteController
