os = require 'os'
_ = require 'underscore'


match = (s1, s2) ->
  # counts how many char are equal
  # from the beginning of 2 strings
  i = 0
  score = 0
  while s1[i] and s2[i]
    if s1[i] == s2[i] then score += 1
    i += 1
  return score


ips_all = ->
  ret = []
  ifaces = os.networkInterfaces()
  names = _.keys(ifaces)
  for name in names
    addrs = ifaces[name]
    for addr in addrs
      ret.push(addr.address)
  return ret


candidates = (addr) ->
  # we return all the ips of the machine sorted by how much they match the
  # 'addr'.  The current matching strategy does not really know about subnets
  # it just does simple string comparison. Seems fine for the moment.
  ips = ips_all()
  ips = _.sortBy(ips, _.partial(match, addr))
  return ips


module.exports =
  candidates: candidates


if not module.parent
  console.log candidates('192.168.1.100')


