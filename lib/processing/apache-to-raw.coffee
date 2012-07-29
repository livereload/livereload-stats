Hierarchy        = require '../hierarchy'
rawentries       = require '../rawentries'

{parseApacheLogLine} = require '../apache'

module.exports = (period, lines) ->
  entries = []

  stats =
    ok: 0
    skipped: 0
    empty: 0
    invalid: 0
    malformed: 0

  for line in lines
    try
      [status, entry] = parseApacheLogLine(line)
    catch e
      console.error "Error while processing:"
      console.error line
      console.error e.stack || e.message || e
      process.exit 1
    entries.push entry if status is 'ok'
    # console.log "Invalid: #{line}" if status is 'invalid'
    stats[status]++

  console.log "#{period}: ok #{stats.ok}, skipped #{stats.skipped}, invalid #{stats.invalid}, malformed #{stats.malformed}, empty #{stats.empty}"

  return entries
