{expect} = require 'chai'
{given, subject, useTempFiles} = require './test-helpers.coffee'
CodeCat = require '../src/codecat.coffee'

describe 'CodeCat', ->

	subject -> new CodeCat('./test/temp/main.js')

	describe '.constructor', ->

		it 'creates an instance', ->
			expect(@subject).to.be.an.instanceof(CodeCat)

	describe 'with javascript', ->

		useTempFiles
			'main.js': '''
				// @codecat-prepend "prepend1.js"
				// @codecat-append "append1.js"
				// @codecat-prepend "prepend2.js"
				// @codecat-append "append2.js"
				
				var main = true;
				'''
			'prepend1.js': 'var prepend1 = true;'
			'append1.js': 'var append1 = true;'
			'prepend2.js': 'var prepend2 = true;'
			'append2.js': 'var append2 = true;'

		describe '#findConcats', ->

			it 'finds prepends', (done) ->
				@subject.findConcats ({prepend}) ->
					done.check ->
						expect(prepend).to.eql(['prepend1.js', 'prepend2.js'])

			it 'finds appends', (done) ->
				@subject.findConcats ({append}) ->
					done.check ->
						expect(append).to.eql(['append1.js', 'append2.js'])

	describe 'with coffeescript', ->
		undefined
