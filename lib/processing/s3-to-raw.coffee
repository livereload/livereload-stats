Hierarchy        = require '../hierarchy'
rawentries       = require '../rawentries'

{parseLogLine} = require '../s3'

module.exports = (period, files) ->
  entries = []

  stats =
    ok: 0
    skipped_url: 0
    skipped_method: 0
    skipped_code: 0
    empty: 0
    invalid: 0
    malformed: 0

  for file in files
    for line in file.stats
      try
        [status, entry] = parseLogLine(line)
      catch e
        console.error "Error while processing:"
        console.error line
        console.error e.stack || e.message || e
        process.exit 1
      if status is 'ok'
        entry.date = period.string
        entries.push entry
      console.log "Invalid:\n#{line}\n" if status is 'invalid'
      stats[status]++

  console.log "    - ok #{stats.ok}, skipped url:#{stats.skipped_url} method:#{stats.skipped_method} code:#{stats.skipped_code}, invalid #{stats.invalid}, malformed #{stats.malformed}, empty #{stats.empty}"

  return entries
