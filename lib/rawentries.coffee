{EventType}      = require './eventtypes'
Hierarchy        = require '../lib/hierarchy'


exports.guessUserId = (entry) -> 'u:' + entry.ip


LOGGED_UNKNOWN_AGENTS = null
UNKNOWN_AGENTS_FILE = 'data/unknown-os-user-agents.txt'
UNKNOWN_AGENTS_STREAM = null
logUnknownAgent = (agent) ->
  unless LOGGED_UNKNOWN_AGENTS?
    LOGGED_UNKNOWN_AGENTS = {}
    try
      data = require('fs').readFileSync(UNKNOWN_AGENTS_FILE, 'utf8')
    catch e
      data = ''
    for line in data.split("\n")
      line = line.trim()
      continue if line.length is 0
      LOGGED_UNKNOWN_AGENTS[line] = yes

  console.log "Unknown user agent: #{agent}"

  unless LOGGED_UNKNOWN_AGENTS[agent]
    LOGGED_UNKNOWN_AGENTS[agent] = yes

    try
      data = require('fs').readFileSync(UNKNOWN_AGENTS_FILE, 'utf8')
    catch e
      data = ''
    data = "#{data}#{agent}\n"
    require('fs').writeFileSync(UNKNOWN_AGENTS_FILE, data)

  return


guessOperatingSystem = (agent) ->
  switch
    when !agent                      then 'none'
    when agent.match(/Darwin\/12\./) then 'mac_10_8'
    when agent.match(/Darwin\/11\./) then 'mac_10_7'
    when agent.match(/Darwin\/10\./) then 'mac_10_6'
    when agent.match(/Windows NT 6\.2/) then 'win_8'
    when agent.match(/Windows NT 6\.1/) then 'win_7'
    when agent.match(/Windows NT 6\.0/) then 'win_vista'
    when agent.match(/Windows NT 5\.2/) then 'win_xp'
    when agent.match(/Windows NT 5\.1/) then 'win_xp'
    when agent.match(/Windows NT 5\.0/) then 'win_2000'
    when agent.match(/Windows XP/) then 'win_xp'
    when agent.match(/Win 9x 4\.9/) then 'win_me'
    when agent.match(/Windows 98/) then 'win_98'
    else
      logUnknownAgent(agent)
      if agent.match(/Windows/)    then 'win_unknown'
      else if agent.match(/Mac OS X/) then 'mac_unknown'
      else                              'unknown'


exports.computeEvents = (entry) ->
  events = ['e:ping']
  events.push "v:version:#{entry.iversion}"  if entry.iversion
  events.push "v:status:#{entry.status}"     if entry.status
  if (entry.platform is 'windows') and (entry.iversion.startsWith '0.')
    events.push "v:platform:windows"
    events.push "v:os:win_any"
  else if entry.agent isnt '-'
    events.push "v:platform:mac"
    events.push "v:os:" + guessOperatingSystem(entry.agent)


  eventsToData = Hierarchy()

  eventData = EventType.single.map(entry)
  for event in events
    eventsToData[event] = eventData

  if stats = entry.stats
    keys = (key.replace(/_(first|last)$/, '') for key in Object.keys(stats)).unique()
    for key in keys
      count = stats[key]
      first = stats[key + '_first']
      last  = stats[key + '_last']

      if count? and first? and last?
        eventsToData['s:' + key] = EventType.aggregate.map({ first, last, count })

  return eventsToData
