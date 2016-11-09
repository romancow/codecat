{EOL} = require 'os'
Readline = require 'readline'
{readFileSync, createReadStream, createWriteStream, statSync} = require 'fs'
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
			encoding:
				value: encoding
			prependRegexp:
				value: getDirectiveRegExp('prepend')
			appendRegexp:
				value: getDirectiveRegExp('append')

	findConcats: (options, callback) ->
		[options, callback] = discernOptions(options, callback)
		{prepend, append} = concats = {prepend: [], append: []}
		lineReader = Readline.createInterface
			input: createReadStream(@source, encoding: @encoding)

		lineReader.on 'line', (line) =>
			if match = line.match(@prependRegexp)?[2]
				prepend.push(match)
			else if match = line.match(@appendRegexp)?[2]
				append.push(match)

		lineReader.on 'close', -> callback?(concats)

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
		{recursive = false} = options
		ensureStream dest, defaultEncoding: @encoding, (stream, end) =>
			@findConcats (concats) =>
				error = null
				resConcats = @_resolveConcats(concats, recursive)
				paths = [resConcats.prepend..., @source, resConcats.append...]
				joinFiles paths, @encoding, stream, options, -> callback?(error)

	@Commenters =
		'': '//'
		js: '//'
		coffee: '#'

	# Private helper functions

	_resolveConcats: (concats, recursive) ->
		resolved = {}
		for own type, files of concats
			resolved[type] = files
				.map((c) => @_resolveConcat(c, recursive))
				.filter (c) -> c?
		return resolved

	_resolveConcat: (concat, recursive) ->
		srcDir = Path.dirname(@source)
		relPath = Path.join(srcDir, concat)
		stats = tryOrNull -> statSync(relPath)
		unless stats?.isFile()
			resNode = -> require.resolve(concat)
			tryOrNull(resNode, "Invalid file or node module \"#{concat}\"")
		else if recursive
			new CodeCat(relPath, @options)
		else
			relPath

	getSourceCommenter = (source) ->
		ext = Path.extname(source).slice(1)
		commenter = CodeCat.Commenters[ext]
		if commenter? then regexpEscape(commenter) else ''

	joinFiles = (files, encoding, stream, options = {}, finishedFn) ->
		{separator = EOL} = options
		callbackForEach files, finishedFn, (file, notFirst, done) ->
			output = (notFirst and separator) or ''
			writeEndCb =
				if file instanceof CodeCat
					-> file.concatTo(stream, options, done)
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

	tryOrNull = (tryFn, error) ->
		try
			tryFn()
		catch
			console.log(error) if error?
			null

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
