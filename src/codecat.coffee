{EOL} = require 'os'
Readline = require 'readline'
{readFileSync, createReadStream, createWriteStream} = require 'fs'
{Writable} = require 'stream'
Path = require 'path'

module.exports = class CodeCat

	constructor: (source, options = {}) ->
		{prefix = 'codecat', commenter = getSourceCommenter(source), encoding = 'utf8'} = options

		getDirectiveRegExp = (directive) ->
			new RegExp("^\\s*#{commenter}\\s*@#{prefix}-#{directive}\\s+([\"']?)(.+?)\\1(\\s|$)")

		Object.defineProperties this,
			source:
				value: source
			prefix:
				value: prefix
			commenter:
				value: commenter
			encoding:
				value: encoding
			prependRegexp:
				value: getDirectiveRegExp('prepend')
			appendRegexp:
				value: getDirectiveRegExp('append')

	findConcats: (options, callback) ->
		[{relative = false}, callback] = discernOptions(options, callback)
		{prepend, append} = concats = {prepend: [], append: []}
		lineReader = Readline.createInterface
			input: createReadStream(@source, encoding: @encoding)

		lineReader.on 'line', (line) =>
			if match = line.match(@prependRegexp)?[2]
				prepend.push(match)
			else if match = line.match(@appendRegexp)?[2]
				append.push(match)

		lineReader.on 'close', =>
			concats = mapConcats(concats, @getRelativePath, this) if relative
			callback?(concats)

	concat: (options, callback) ->
		[options, callback] = discernOptions(options, callback)
		concatted = ''
		write = (chunk, encoding, cb) ->
			concatted += chunk
			cb?(null)
		stream = new Writable(write: write)
		@concatTo stream, options, (error) -> callback?(concatted)

	concatTo: (dest, options, callback) ->
		[{separator = EOL}, callback] = discernOptions(options, callback)
		@findConcats relative: true, (concats) =>
			error = null
			paths = [concats.prepend..., @source, concats.append...]
			ensureStream dest, defaultEncoding: @encoding, (stream) ->
				joinFiles(paths, @encoding, separator, stream)
				stream.end -> callback?(error)

	getRelativePath: (file) ->
		sourceDir = Path.dirname(@source)
		Path.join(sourceDir, file)
	
	@Commenters =
		'': '//'
		js: '//'
		coffee: '#'

	# Private helper functions

	getSourceCommenter = (source) ->
		ext = Path.extname(source).slice(1)
		commenter = CodeCat.Commenters[ext]
		if commenter? then regexpEscape(commenter) else ''

	joinFiles = (paths, encoding, separator, stream) ->
		paths.forEach (path, notFirst) ->
			output = (notFirst and separator) or ''
			output += readFileSync(path, encoding: encoding)
			stream.write(output)

	ensureStream = (dest, options, fn) ->
		[options, fn] = discernOptions(options, fn)
		if isString(dest)
			stream = createWriteStream(dest, options)
			stream.once('open', -> fn(stream))
		else
			fn(dest)

	mapConcats = (concats, map, thisArg) ->
		mapped = {}
		for own type, files of concats
			mapped[type] = files.map(map, thisArg)
		return mapped

	# General utility functions

	regexpEscape = (str) ->
		str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&')
	
	isString = (val) ->
		(typeof val is 'string') or (val instanceof String)

	discernOptions = (options, fn) ->
		if options instanceof Function
			[{}, options]
		else
			[options ? {}, fn]
