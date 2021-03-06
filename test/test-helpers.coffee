{writeFileSync, unlinkSync} = require 'fs'
Path = require 'path'

given = (name, fn) ->
	beforeEach "given #{name}", ->
		[cache, isCached] = [null, false]
		Object.defineProperty this, name,
			configurable: true,
			get: ->
				unless isCached
					isCached = true
					cache = fn.call(this)
				return cache
			set: (val) ->
				isCached = true
				cache = val
	afterEach ->
		delete @subject

subject = (fn) -> given('subject', fn)

useTempFiles = (tempFiles) ->
	before 'creating temp files', ->
		for file, data of tempFiles
			path = Path.join('test', 'temp', file)
			writeFileSync(path, data)
	after 'deleting temp files', ->
		for file of tempFiles
			path = Path.join('test', 'temp', file)
			unlinkSync(path)
	tempFiles
	

Function::check = (expectation) ->
	try
		expectation()
	catch error
	finally
		this(error)

module.exports =
	given: given
	subject: subject
	useTempFiles: useTempFiles
