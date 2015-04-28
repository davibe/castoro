ffmpeg = require 'fluent-ffmpeg'

class FFMpegRegistry
  # collect all ffmpeg instances we use
  # to kill them if needed
  @ffs = []
  @get: ->
    ret = ffmpeg.apply(ffmpeg, arguments)
    @ffs.push(ret)
    return ret
  @killAll: ->
    @ffs.forEach (ff) ->
      # there is no way to do this cleanly,
      # we always get some kind of error in the console
      try
        ff.kill()
      catch e
  
module.exports = FFMpegRegistry

