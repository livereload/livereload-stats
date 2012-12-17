require 'sugar'

fs    = require 'fs'
Path  = require 'path'
util  = require 'util'

{DataFileGroups} = require '../lib/datafiles'
filecrunching    = require '../lib/filecrunching'

options = require('dreamopt') [
  "Usage: node bin/report.js"

  "Generic options:"
]

die = (message) ->
  util.debug message
  process.exit 1


withTiming = (message, func) ->
  console.time message if message
  result = func()
  console.timeEnd message if message
  return result


loadViews = (viewsDir) ->
  jade = require 'jade'

  views = {}
  for fileName in fs.readdirSync(viewsDir) when fileName.endsWith('.jade')
    field    = fileName.replace /\.jade$/, ''
    filePath = Path.join(viewsDir, fileName)

    views[field] = jade.compile(fs.readFileSync(filePath, 'utf-8'), filename: filePath)

  return views


hashToArray = (hash, levels) ->
  if levels == 0
    return hash

  array = []

  for key in Object.keys(hash).sort()
    value = hash[key]
    value = hashToArray(value, levels - 1)

    value.key = key
    array.push value

  return array


temporalTransform = (lastN, periodsToData, levels) ->
  keys = (Object.keys(data) for own period, data of periodsToData).flatten().union().sort()
  periods = (period for own period, data of periodsToData).sort().last(lastN)
  lastPeriod = periods[periods.length - 1]

  result =
    cols:
      for period in periods
        {
          title: period
        }
    rows:
      for key in keys when periods.any((pediod) -> periodsToData[period][key])
        {
          key: key
          cols:
            for period in periods
              {
                # title: period
                value: periodsToData[period][key] || ''
              }
          value: periodsToData[lastPeriod][key] || {}
        }



loadData = (groupName, func) ->
  group = DataFileGroups[groupName]

  withTiming "load #{groupName}", ->
    periodsToData = {}
    for file in group.allFiles()
      periodsToData[file.id] = file.readSync()

    func(periodsToData, group.levels)


groupSegments = (sourceSegments, sourceGroups) ->
  ungroupedSegments = Object.clone(sourceSegments)

  groups = (Object.clone(group) for group in sourceGroups)
  otherGroup = groups.pop()

  for group in groups
    group.regexp = new RegExp(("^" + RegExp.escape(key) for key in group.keys).join("|"))

    groupRows = []

    for keyPrefix in group.hideKeys or []
      ungroupedSegments.rows = (row for row in ungroupedSegments.rows when !row.key.startsWith(keyPrefix))
    for keyPrefix in group.keys
      otherRows = []
      for row in ungroupedSegments.rows
        if row.key.startsWith(keyPrefix)
          groupRows.push(row)
        else
          otherRows.push(row)
      ungroupedSegments.rows = otherRows

    if group.sort
      groupRows = groupRows.sortBy((row) -> -row.value.count)
    if group.min
      groupRows = groupRows.filter((row) -> row.value.count >= group.min)

    group.segments = { cols: ungroupedSegments.cols, rows: groupRows }

  if ungroupedSegments.rows.length > 0
    otherGroup.segments = ungroupedSegments
    groups.push(otherGroup)

  return groups


views = loadViews(Path.join(__dirname, '../views'))


segments = loadData('month-segments', temporalTransform.fill(10))

groups = groupSegments segments, [
  { title: "", keys: ["g:all"] }
  { title: "By engagement", keys: ["g:engagement:"] }
  { title: "By engagement history", keys: ["g:status:"] }
  { title: "By build type", keys: ["g:v:status:", "g:active:v:status:"] }
  { title: "By age", keys: ["g:knownfor:"] }
  { title: "By OS", keys: ["g:v:platform:", "g:v:os:"] }
  { title: "By OS (active users only)", keys: ["g:active:v:platform:", "g:active:v:os:"] }
  { title: "By version", keys: ["g:v:version:"] }
  { title: "By version (active users only)", keys: ["g:active:v:version:"] }
  { title: "By additional monitoring extensions", keys: ["g:v:ext:"], hideKeys: ["g:active:v:ext:"], sort: yes, min: 2 }
  { title: "Other segments"}
]


html = views.layout {
  title: "LiveReload Statistics"
  breadcrumbs: [
    { title: "LiveReload Statistics", active: yes }
  ]
  content: views.index({ groups })
}

DataFileGroups.html.mkdir()
fs.writeFileSync DataFileGroups.html.subpath('index.html'), html
