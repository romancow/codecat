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

	concat: (options, callback) ->
		{newline = EOL} = options
		@findConcats (concats) ->
			concatted = ''
			concats?.prepends?.forEach (prepend) ->
				concatted += readFileSync(prepend, encoding: @encoding)
				concatted += newline
			concatted += readFileSync(@source, encoding: @encoding)
			concats?.appends?.forEach (append) ->
				concatted += newline
				concatted += readFileSync(append, encoding: @encoding)
			callback?(concatted)

	concatTo: (file, options, callback) ->
		{newline = EOL} = options
		@findConcats (concats) ->
			error = null
			stream = createWriteStream(file, defaultEncoding: @encoding)
			stream.once 'open', ->
				concats?.prepends?.forEach (prepend) ->
					write = readFileSync(prepend, encoding: @encoding)
					write += newline
					stream.write(write)
				write = readFileSync(@source, encoding: @encoding)
				stream.write(write)
				concats?.appends?.forEach (append) ->
					write = newline
					write += readFileSync(append, encoding: @encoding)
					stream.write(write)
				stream.end()
				callback?(error)

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
