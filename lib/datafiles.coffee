fs    = require 'fs'
Path  = require 'path'

Hierarchy = require './hierarchy'


outputDir = Path.join(__dirname, '../data')


class DataFileGroup

  constructor: (@subdir, @granularity, @levels, @suffix = '-' + @subdir) ->
    @path     = Path.join(outputDir, @subdir)
    @fsSuffix = "#{@suffix}.json"
    @regexp   = RegExp(RegExp.escape(@fsSuffix) + '$')

  idToFileName: (id)   -> id + @fsSuffix

  fileNameToId: (name) -> name.replace(@regexp, '')

  allFiles: ->
    @mkdir()
    for fileName in fs.readdirSync(@path).sort() when fileName.match(@regexp)
      new DataFile(this, Path.join(@path, fileName), @fileNameToId(fileName))

  file: (id) ->
    new DataFile(this, Path.join(@path, @idToFileName(id)), id)

  mkdir: ->
    unless Path.existsSync(@path)
      fs.mkdirSync(@path, 0o0770)

  subpath: (subpath) -> Path.join(@path, subpath)

  parse: (data) -> JSON.parse(data)


class ApacheDataFileGroup extends DataFileGroup

  constructor: (subdir) ->
    super(subdir, 'day', 0, '')
    @regexp = /^access_log\.\d{8}$/

  idToFileName: (id)   -> "access_log.#{id.replace(/-/g, '')}"

  fileNameToId: (name) -> name.replace('access_log.', '').replace(/^(\d\d\d\d)(\d\d)(\d\d)/, (_, y, m, d) -> "#{y}-#{m}-#{d}")

  parse: (data) -> data.split("\n")


class S3DataFileGroup extends DataFileGroup

  constructor: (subdir) ->
    super(subdir, 'subday', 0, '')
    @regexp = /^access_log-/

  idToFileName: (id)   -> throw new Error "Unsupported"

  fileNameToId: (name) -> name.replace(/^access_log-/, '').replace(/^(\d\d\d\d)-(\d\d)-(\d\d)-(.*)$/, (_, y, m, d, q) -> "#{y}-#{m}-#{d}-#{q}")

  parse: (data) -> data.split("\n")



class DataFile
  constructor: (@group, @path, @id) ->
    @name = Path.basename(@path)

  exists:    -> Path.existsSync(@path)

  readSync:  ->
    result = @group.parse(fs.readFileSync(@path, 'utf8'))
    if @group.levels > 0
      Hierarchy(result, @group.levels)
    else
      result

  writeSync: (data) ->
    unless Path.existsSync(Path.dirname(@path))
      fs.mkdirSync(Path.dirname(@path), 0o0770)
    fs.writeFileSync(@path, JSON.stringify(data, null, 2))

  timestamp: ->
    try
      fs.statSync(@path).mtime.getTime()
    catch e
      0


exports.DataFileGroups = DataFileGroups =
  apache:  new ApacheDataFileGroup('apache')
  s3:      new S3DataFileGroup('s3')
  raw:     new DataFileGroup('raw',     'day',    0,  '')
  rawxx:   new DataFileGroup('rawxx',   'day',    0,  '')
  html:    new DataFileGroup('html',    'none',   0,  '')

CATEGORIES = [
  ['events', 2]
  ['events-cum', 2]
  ['users', 1]
  ['users-temp', 1]
  ['segments', 1]
]

do ->
  for [ category, levels ] in CATEGORIES
    for granularity in require('./granularities').all
      name = "#{granularity}-#{category}"
      DataFileGroups[name] = new DataFileGroup(name, granularity, levels)
