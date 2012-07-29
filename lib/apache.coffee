{sprintf} = require './sprintf'

MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

# "[^"\\]*(?:\\.[^"\\]*)*" is a regexp to match a double-quoted string with escapes
REGEXP = /^((?:unknown|\d+\.\d+\.\d+\.\d+|[0-9a-f]*:[0-9a-f:]*)(?:,\s{0,4}(?:unknown|\d+\.\d+\.\d+\.\d+|[0-9a-f]*:[0-9a-f:]*))*) - - \[(\d+?)\/(\w+?)\/(\d+?):(\d+?):(\d+?):(\d+?) [+?]\d+?\] "(GET|HEAD|POST) (.*) HTTP\/1.[01]" (\d+?) (?:\d+?|-) "[^"\\]*(?:\\.[^"\\]*)*" ("[^"\\]*(?:\\.[^"\\]*)*)"$/

parseQueryString = (qs) ->
  params = {}
  for kv in qs.split('&')
    if (pos = kv.indexOf('=')) >= 0
      k = decodeURIComponent kv.substr(0, pos)
      v = decodeURIComponent kv.substr(pos + 1)

      if k is 'v'
        params.version = v
      else if k is 'iv'
        params.iversion = v
      else if k.startsWith 'stat.'
        params.stats ||= {}
        params.stats[k.replace(/\./g, '_')] = v
      else
        params[k] = v
  return params

exports.parseApacheLogLine = (line) ->
  line = line.trim()
  return ['empty'] if line.length == 0

  unless match = line.match REGEXP
    return ['invalid']

  [dummy, ip, day, monthName, year, hour, min, sec, method, url, code, ua] = match

  try
    url = decodeURIComponent(url)
  catch e
    return ['malformed']

  if !url.startsWith('/ping.php?')
    return ['skipped_url']
  if method isnt 'GET'
    return ['skipped_method']
  if code isnt '200'
    return ['skipped_code']

  params = parseQueryString url.replace('/ping.php?', '')

  month = MONTHS.indexOf(monthName)
  if month < 0
    throw new Error("Unknown month: '#{monthName}'")
  month += 1

  date = sprintf("%04d-%02d-%02d", parseInt(year, 10), month, parseInt(day, 10))
  time = Math.round(Date.UTC(parseInt(year, 10), month-1, parseInt(day, 10), parseInt(hour, 10), parseInt(min, 10), parseInt(sec, 10))/1000)

  params.date  = date
  params.time  = time
  params.ip    = ip
  params.agent = ua

  return ['ok', params]
