{sprintf} = require './sprintf'

MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

REGEXP = /\[(\d+?)\/(\w+?)\/(\d+?):(\d+?):(\d+?):(\d+?) [+?]\d+?\] "GET (.*) HTTP\/1.[01]" \d+? \d+? "([^"]*)" "([^"]*)"$/

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
        params.stats[k.replace(/\./g, '-')] = v
      else
        params[k] = v
  return params

exports.parseApacheLogLine = (line) ->
  line = line.trim()
  return ['empty'] if line.length == 0

  unless match = line.match REGEXP
    return ['invalid']

  [dummy, day, monthName, year, hour, min, sec, url, referrer, ua] = match

  try
    url = decodeURIComponent(url)
  catch e
    return ['malformed']

  if !url.startsWith('/ping.php?')
    return ['skipped']

  params = parseQueryString url.replace('/ping.php?', '')

  month = MONTHS.indexOf(monthName)
  if month < 0
    throw new Error("Unknown month: '#{monthName}'")
  month += 1

  date = sprintf("%04d-%02d-%02d", parseInt(year, 10), month, parseInt(day, 10))
  time = Math.round(new Date(parseInt(year, 10), month-1, parseInt(day, 10), parseInt(hour, 10), parseInt(min, 10), parseInt(sec, 10)).getTime()/1000)

  params.date  = date
  params.time  = time
  params.ip    = '?'
  params.agent = ua

  return ['ok', params]
