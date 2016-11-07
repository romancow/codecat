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
			options:
				value: options
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
		[options, callback] = discernOptions(options, callback)
		ensureStream dest, defaultEncoding: @encoding, (stream, end) =>
			concatToStream.call(this, stream, options, -> end(callback))

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

	concatToStream = (stream, options, callback) ->
		{recursive = true} = options
		{encoding, source} = this
		@findConcats relative: true, (concats) ->
			error = null
			concats = mapConcats(concats, (c) => new CodeCat(c, @options)) if recursive
			paths = [concats.prepend..., source, concats.append...]
			joinFiles paths, encoding, stream, options, -> callback?(error)
	
	joinFiles = (files, encoding, stream, options = {}, finishedFn) ->
		{separator = EOL} = options
		callbackForEach files, finishedFn, (file, notFirst, done) ->
			output = (notFirst and separator) or ''
			writeEndCb =
				if file instanceof CodeCat
					-> concatToStream.call(file, stream, options, done)
				else
					output += readFileSync(file, encoding: encoding)
					done
			stream.write(output, encoding, writeEndCb)

	ensureStream = (dest, options, fn) ->
		[options, fn] = discernOptions(options, fn)
		if isString(dest)
			stream = createWriteStream(dest, options)
			end = (endCb) -> stream.end(endCb)
			stream.once('open', -> fn(stream, end))
		else
			end = (endCb) -> endCb?()
			fn(dest, end)

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

	# this method calls the given callback for each item in the collection, then calls
	# the "done" method once each callback has called their given "done" methods
	callbackForEach = (collection, done, callback) ->
		[total, current] = [collection.length, 0]
		do callbackCurrent = ->
			item = collection[current]
			called = false
			callback item, current, (error) ->
				console.error(error) if error?
				unless called
					called = true
					if ++current >= total
						done()
					else
						callbackCurrent()
