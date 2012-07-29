Hierarchy        = require '../hierarchy'
rawentries       = require '../rawentries'

{parseApacheLogLine} = require '../apache'

module.exports = (period, lines) ->
  entries = []

  stats =
    ok: 0
    skipped_url: 0
    skipped_method: 0
    skipped_code: 0
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
    if status is 'ok'
      entry.date = period
      entries.push entry
    console.log "Invalid:\n#{line}\n" if status is 'invalid'
    stats[status]++

  console.log "    - ok #{stats.ok}, skipped url:#{stats.skipped_url} method:#{stats.skipped_method} code:#{stats.skipped_code}, invalid #{stats.invalid}, malformed #{stats.malformed}, empty #{stats.empty}"

  return entries
