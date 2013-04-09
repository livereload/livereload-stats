{sprintf} = require './sprintf'

MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

# "[^"\\]*(?:\\.[^"\\]*)*" is a regexp to match a double-quoted string with escapes

VALUE_RE = ///
  (?:                                       # either a non-quoted string without spaces
    [^"\s]
    [^\s]*
  |                                         # or a quoted string:
    "                                       #   - an opening quote
      [^"\\]*                               #   - a run of non-escaped characters
      (?:                                   #   - then zero or more of:
        \\ .                                #     - escape character (slash) followed by any character
        [^"\\]*                             #     - another run of non-escaped characters
      )*
    "                                       #   - finally, a closing quote
  )
///.toString().replace(/^\//, '').replace(/\/$/, '')

TIME_RE = ///                               # e.g. [04/Aug/2006:22:34:02 +0000]
  \[
    ( \d+? )                                # 1: day (04)
    /
    ( \w+? )                                # 2: month (Aug)
    /
    ( \d+? )                                # 3: year (2006)
    :
    ( \d+? )                                # 4: hour (22)
    :
    ( \d+? )                                # 5: minute (34)
    :
    ( \d+? )                                # 6: second (02)
    \s
    [+-]\d+?                                # time zone offset (ignored)
  \]
///.toString().replace(/^\//, '').replace(/\/$/, '')

IP_RE = ///
  (?:                                       # either literal "unknown"
    unknown
  |                                         # or IPv4 address
    \d+ \. \d+ \. \d+ \. \d+                #   (four numbers separated by periods)
  |                                         # or IPv6 address
    [0-9a-f]*                               #   which is a bunch of hex
    :                                       #   that always contains at least one colon
    [0-9a-f:]*                              #   but most often looks like a mess of colons and hex digits
  )
///.toString().replace(/^\//, '').replace(/\/$/, '')

REGEXP = ///^
  (?: [0-9a-f]+ | - )                       # bucket owner (hex) - 314159b66967d86f0...
  \s
  ( #{VALUE_RE} )                           # 1: bucket - mybucket
  \s
  (?: #{TIME_RE} | - )                      # 2,3,4,5,6,7: time - [04/Aug/2006:22:34:02 +0000]
  \s
  ( #{IP_RE} | - )                          # 8: ip - 72.21.206.5
  \s
  #{VALUE_RE}                               # requester (ignored) - 314159b66967d86f0...
  \s
  #{VALUE_RE}                               # request id (ignored) - 3E57427F33A59F07
  \s
  ( #{VALUE_RE} )                           # 9: operation - REST.GET.OBJECT, REST.PUT.OBJECT
  \s
  ( #{VALUE_RE} )                           # 10: key - /photos/2006/08/puppy.jpg
  \s
  ( #{VALUE_RE} )                           # 11: Request-URI - "GET /mybucket/photos/2006/08/puppy.jpg?x-foo=bar"
  \s
  ( - | \d+ )                               # 12: HTTP status - 200
  \s
  #{VALUE_RE}                               # error code (ignored) - NoSuchBucket
  \s
  (?: - | \d+ )                             # bytes sent (ignored) - 2662992
  \s
  (?: - | \d+ )                             # object size (ignored) - 3462992
  \s
  (?: - | \d+ )                             # total time, ms (ignored) - 70
  \s
  (?: - | \d+ )                             # turn-around time, ms (ignored) - 10
  \s
  #{VALUE_RE}                               # HTTP referrer - "http://www.amazon.com/webservices"
  \s
  ( #{VALUE_RE} )                           # 13: user agent - "curl/7.15.1"
  \s
  #{VALUE_RE}                               # version id (ignored) - 3HL4kqtJvjVBH40Nrjfkd

  (?: $ | \s )                              # the spec allows for more fields to be added later, so either end of string or a space
///

console.log "regexp = " + REGEXP

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

unquote = (s) ->
  if s.match(/^"/) and s.match(/"$/)
    s.substr(1, s.length - 2).replace(/\\(.)/g, '$1')
  else
    s

exports.parseLogLine = (line) ->
  line = line.trim()
  return ['empty'] if line.length == 0

  unless match = line.match REGEXP
    return ['invalid']

  [dummy, bucket, day, monthName, year, hour, min, sec, ip, operation, key, url, code, ua] = match

  bucket    = unquote(bucket)
  ip        = unquote(ip)
  operation = unquote(operation)
  key       = unquote(key)
  url       = unquote(url)
  ua        = unquote(ua)

  if operation isnt 'REST.GET.OBJECT'
    return ['skipped_method']
  if code isnt '200'
    return ['skipped_code']

  unless url.match /^GET\s+/
    console.log "bad Request-URI: #{url}"
    return ['malformed']
  unless url.match /\s+HTTP\/\d\.\d$/
    console.log "bad Request-URI end: #{url}"
    return ['malformed']
  url = url.replace(/^GET\s+/, '').replace(/\s+HTTP\/\d\.\d$/, '')

  try
    url = decodeURIComponent(url)
  catch e
    return ['malformed']

  if !url.startsWith('/news.json?')
    console.log "bad url: #{url}"
    return ['skipped_url']

  params = parseQueryString url.replace('/news.json?', '')

  month = MONTHS.indexOf(monthName)
  if month < 0
    throw new Error("Unknown month: '#{monthName}'")
  month += 1

  date = sprintf("%04d-%02d-%02d", parseInt(year, 10), month, parseInt(day, 10))
  time = Math.round(Date.UTC(parseInt(year, 10), month-1, parseInt(day, 10), parseInt(hour, 10), parseInt(min, 10), parseInt(sec, 10))/1000)

  if ua is '-'
    ua = ''

  params.date  = date
  params.time  = time
  params.ip    = ip
  params.agent = ua

  return ['ok', params]
