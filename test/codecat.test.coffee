chai = require 'chai'
chai.use(require 'chai-string')
chai.use(require 'chai-fs')
{expect} = chai
{readFileSync, unlink} = require 'fs'
{given, subject, useTempFiles} = require './test-helpers.coffee'
CodeCat = require '../src/codecat.coffee'

describe 'CodeCat', ->
	given 'source', -> './test/temp/main.js'
	subject -> new CodeCat(@source)

	describe '.constructor', ->

		it 'creates an instance', ->
			expect(@subject).to.be.an.instanceof(CodeCat)

	describe 'with javascript', ->
		tempFiles = useTempFiles
			'main.js': '''
				// @codecat-prepend "prepend1.js"
				// @codecat-append "append1.js"
				// @codecat-prepend "prepend2.js"
				// @codecat-append "append2.js"
				
				var main = true;
				'''
			'prepend1.js': 'var prepend1 = true;'
			'append1.js': '''
				// @codecat-prepend "prepend3.js"
				var append1 = true;
				'''
			'prepend2.js': 'var prepend2 = true;'
			'append2.js': 'var append2 = true;'
			'prepend3.js': 'var prepend3 = true;'

		describe '#findConcats', ->

			it 'finds prepends', (done) ->
				@subject.findConcats ({prepend}) ->
					done.check ->
						expect(prepend).to.eql(['prepend1.js', 'prepend2.js'])

			it 'finds appends', (done) ->
				@subject.findConcats ({append}) ->
					done.check ->
						expect(append).to.eql(['append1.js', 'append2.js'])

		describe '#concat', ->

			it 'has original file contents', (done) ->
				@subject.concat (result) ->
					done.check ->
						expect(result).to.contain(tempFiles['main.js'])

			it 'prepends file contents', (done) ->
				prepended = ['prepend1.js', 'prepend2.js']
					.map (name) -> tempFiles[name]
					.join('\n')
				@subject.concat (result) ->
					done.check ->
						expect(result).to.startWith(prepended)

			it 'appends files contents', (done) ->
				appended = ['prepend3.js', 'append1.js', 'append2.js']
					.map (name) -> tempFiles[name]
					.join('\n')
				@subject.concat (result) ->
					done.check ->
						expect(result).to.endWith(appended)
			
		describe '#concatTo', ->
			given 'destination', -> 'test/temp/result.js'
			given 'fileContent', -> readFileSync(@destination, encoding: 'utf8')

			after 'delete result file', -> unlink(@destination)

			it 'creates a file', (done) ->
				@subject.concatTo @destination, =>
					done.check =>
						expect(@destination).to.be.a.file()

			it 'has orignal file', (done) ->
				@subject.concatTo @destination, =>
					done.check =>
						expect(@fileContent).to.contain(tempFiles['main.js'])

			it 'prepends files', (done) ->
				prepended = ['prepend1.js', 'prepend2.js']
					.map (name) -> tempFiles[name]
					.join('\n')
				@subject.concatTo @destination, =>
					done.check =>
						expect(@fileContent).to.startWith(prepended)

			it 'appends files', (done) ->
				appended = ['prepend3.js', 'append1.js', 'append2.js']
					.map (name) -> tempFiles[name]
					.join('\n')
				@subject.concatTo @destination, =>
					done.check =>
						expect(@fileContent).to.endWith(appended)

	describe 'with coffeescript', ->
		given 'source', -> './test/temp/main.coffee'

		tempFiles = useTempFiles
			'main.coffee': '''
				# @codecat-prepend 'prepend1.coffee'
				# @codecat-append 'append1.coffee'
				# @codecat-prepend 'prepend2.coffee'
				# @codecat-append 'append2.coffee'
				
				main = true
				'''
			'prepend1.coffee': 'prepend1 = true'
			'append1.coffee': '''
				# @codecat-prepend 'prepend3.coffee'
				append1 = true
				'''
			'prepend2.coffee': 'prepend2 = true'
			'append2.coffee': 'append2 = true'
			'prepend3.coffee': 'prepend3 = true'

		describe '#findConcats', ->

			it 'finds prepends', (done) ->
				@subject.findConcats ({prepend}) ->
					done.check ->
						expect(prepend).to.eql(['prepend1.coffee', 'prepend2.coffee'])

			it 'finds appends', (done) ->
				@subject.findConcats ({append}) ->
					done.check ->
						expect(append).to.eql(['append1.coffee', 'append2.coffee'])

		describe '#concat', ->

			it 'has original file contents', (done) ->
				@subject.concat (result) ->
					done.check ->
						expect(result).to.contain(tempFiles['main.coffee'])

			it 'prepends file contents', (done) ->
				prepended = ['prepend1.coffee', 'prepend2.coffee']
					.map (name) -> tempFiles[name]
					.join('\n')
				@subject.concat (result) ->
					done.check ->
						expect(result).to.startWith(prepended)

			it 'appends files contents', (done) ->
				appended = ['prepend3.coffee', 'append1.coffee', 'append2.coffee']
					.map (name) -> tempFiles[name]
					.join('\n')
				@subject.concat (result) ->
					done.check ->
						expect(result).to.endWith(appended)
			
		describe '#concatTo', ->
			given 'destination', -> 'test/temp/result.coffee'
			given 'fileContent', -> readFileSync(@destination, encoding: 'utf8')

			after 'delete result file', -> unlink(@destination)

			it 'creates a file', (done) ->
				@subject.concatTo @destination, =>
					done.check =>
						expect(@destination).to.be.a.file()

			it 'has orignal file', (done) ->
				@subject.concatTo @destination, =>
					done.check =>
						expect(@fileContent).to.contain(tempFiles['main.coffee'])

			it 'prepends files', (done) ->
				prepended = ['prepend1.coffee', 'prepend2.coffee']
					.map (name) -> tempFiles[name]
					.join('\n')
				@subject.concatTo @destination, =>
					done.check =>
						expect(@fileContent).to.startWith(prepended)

			it 'appends files', (done) ->
				appended = ['prepend3.coffee', 'append1.coffee', 'append2.coffee']
					.map (name) -> tempFiles[name]
					.join('\n')
				@subject.concatTo @destination, =>
					done.check =>
						expect(@fileContent).to.endWith(appended)
