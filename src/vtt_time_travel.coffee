fs = require('fs')
os = require('os')
moment = require('moment')

durationToString = (x) ->
  ms = x.asMilliseconds()
  if ms < 0 then return "00:00:00.000"
  return moment.utc(ms).format("HH:mm:ss.SSS")


vttTimeTravel = (buffer, shift) ->
  shift = shift || 0
  buffer = buffer.toString()
  lines = buffer.split(os.EOL)

  res = []
  lines.forEach (line) ->
    matches = line.match(/(..:..:..\....) --> (..:..:..\....)(.*)/)
    format = "HH:mm:ss.SSS"
    if matches
      start = matches[1]
      end = matches[2]
      # tail -> just in case there is something lse on the line
      tail = matches[3] || ""
      start = moment.duration(start)
      end = moment.duration(end)
      start = start.subtract(shift, 's')
      end = end.subtract(shift, 's')
      start = durationToString(start)
      end = durationToString(end)
      result = "#{start} --> #{end}#{tail}"
      res.push(result)
      return
    res.push(line)

  res = res.join(os.EOL)
  res = new Buffer(res)
  return res
  
module.exports = vttTimeTravel


#fs.readFile('data/sub.vtt', start)
