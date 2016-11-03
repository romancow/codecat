{EOL} = require 'os'
Readline = require 'readline'
{readFileSync, createReadStream, createWriteStream} = require 'fs'
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

	findConcats: (callback) ->
		[prepends, appends] = [[], []]
		lineReader = Readline.createInterface
			input: createReadStream(@source, encoding: @encoding)

		lineReader.on 'line', (line) =>
			if match = line.match(@prependRegexp)?[2]
				prepends.push(match)
			else if match = line.match(@appendRegexp)?[2]
				appends.push(match)

		lineReader.on 'close', ->
			callback?(prepend: prepends, append: appends)

	concat: (options = {}, callback) ->
		[options, callback] = [{}, options] if options instanceof Function
		{newline = EOL} = options
		@findConcats (concats) =>
			concatted = ''
			concats?.prepend?.map (prepend) => @getRelativePath(prepend)
				.forEach (prependPath) ->
					concatted += readFileSync(prependPath, encoding: @encoding)
					concatted += newline
			concatted += readFileSync(@source, encoding: @encoding)
			concats?.append?.map (append) => @getRelativePath(append)
				.forEach (appendPath) ->
					concatted += newline
					concatted += readFileSync(appendPath, encoding: @encoding)
			callback?(concatted)

	concatTo: (file, options, callback) ->
		[options, callback] = [{}, options] if options instanceof Function
		{newline = EOL} = options
		@findConcats (concats) =>
			error = null
			stream = createWriteStream(file, defaultEncoding: @encoding)
			stream.once 'open', =>
				concats?.prepend?.map (prepend) => @getRelativePath(prepend)
					.forEach (prependPath) ->
						write = readFileSync(prependPath, encoding: @encoding)
						write += newline
						stream.write(write)
				write = readFileSync(@source, encoding: @encoding)
				stream.write(write)
				concats?.append?.map (append) => @getRelativePath(append)
					.forEach (appendPath) ->
						write = newline
						write += readFileSync(appendPath, encoding: @encoding)
						stream.write(write)
				stream.end ->
					callback?(error)

	getRelativePath: (file) ->
		sourceDir = Path.dirname(@source)
		Path.join(sourceDir, file)
	
	@Commenters =
		'': '//'
		js: '//'
		coffee: '#'

	getSourceCommenter = (source) ->
		ext = Path.extname(source).slice(1)
		commenter = CodeCat.Commenters[ext]
		if commenter? then regexpEscape(commenter) else ''

	regexpEscape = (str) ->
		str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&')
