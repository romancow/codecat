{execSync} = require 'child_process'

libName  = 'codecat'
srcFile = "./src/#{libName}.coffee"
destFile = "./dist/#{libName}.js"
minFile  = "./dist/#{libName}.min.js"

task 'lint', 'Lint project coffeescript', (options) ->
	tryExecSync("coffeelint #{srcFile}")

task 'test', 'Run tests on project coffeescript', (options) ->
	tryExecSync('mocha', compilers: 'coffee:coffee-script/register')

task 'build', 'Build project with header', (options) ->
	return unless invoke('lint')
	tryExecSync('coffee', compile: true, output: 'dist/', ['src/'])

task 'prepublish', 'Build and test before publishing', (options) ->
	success = ['build', 'test'].every (name) -> invoke(name)
	# we want to throw an error if the prepublish fails
	success or throw new Error('prepublish failed!')

joinOptions = (options = {}) ->
	opts = for opt, val of options when val
		"--#{opt}" + (if val is true then '' else " #{val}")
	opts.join(' ')

tryExecSync = (cmd, options = {}, args = []) ->
	error = null
	[options, args] = [{}, options] if Array.isArray(options)
	cmd += " #{joinOptions(options)}"
	cmd += ['', args...].join(' ') if args?.length
	try
		execSync(cmd, stdio: 'inherit')
	catch error
		console.log(error.message)
	not error
