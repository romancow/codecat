{execSync} = require 'child_process'

task 'test', 'Run tests on project coffeescript', (options) ->
	tryExecSync('mocha', compilers: 'coffee:coffee-script/register')

task 'build', 'Build project with header', (options) ->
	undefined

joinOptions = (options = {}) ->
	opts = for opt, val of options when val
		"--#{opt}" + (if val is true then '' else " #{val}")
	opts.join(' ')

tryExecSync = (cmd, options) ->
	error = null
	cmd += " #{joinOptions(options)}" if options?
	try
		execSync(cmd, stdio: 'inherit')
	catch error
		console.log(error.message)
	not error
