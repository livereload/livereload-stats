Hierarchy        = require '../hierarchy'
rawentries       = require '../rawentries'

module.exports = (period, stats) ->
  usersToEventsToData = Hierarchy()
  for entry in stats
    if userId = rawentries.guessUserId(entry)
      usersToEventsToData.add userId, rawentries.computeEvents(entry)
  return usersToEventsToData
