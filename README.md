# CodeCat

A simple, free, and easy to use tool for combining code.

[[Overview](#overview) | [Installation](#installation) | [Use & Examples](#use-examples)]


## Overview

CodeCat is a library for concatenating javascript and coffeescript files in the style of apps like [CodeKit](https://codekitapp.com/) 
and [Prepros](https://prepros.io/). Instead of needing an app, however, you can do it programmatically with CodeCat.

### Why?

Have a project meant for the browser, but feel like webpack and browserify are overkill?

Tired of third party config files and plugins?

Want more direct control of your build process?

Want to keep the structure and layout of your code within the code itself, instead of hidden in configs and task runners?
 
Have an existing project that uses CodeKit or Prepros and need an easily-swappable, free, GUI-less, platform-agnostic alternative?

Have a callaborator that wants to use one of these, but don't want the project to be tied to a paid app?

CodeCat can help.


## Installation

### NPM
As a development dependency:

`npm install --save-dev codecat`

As a global module:

`npm install -g codecat`

### Yarn
As a development dependency:

`yarn add codecat --dev`

As a global module:

`yarn global add codecat`

### Download

Or download the [distribution file](https://raw.githubusercontent.com/romancow/codecat/master/dist/codecat.js) from GitHub.


## Use & Examples

### Directives
Specifying a file to concatenate in your code is easy. Simply add a commented "directive" to your code. Since the directives are not 
valid javascript, they are single line comments. There are two you can use, `prepend` and `append`:

```javascript
// @codecat-prepend "some_file.js"

// put main code here
var result = doSomething();
if (result.success) {
	alert("Congratulations!");
}
else {
	alert("My condolences.");
}

// @codecat-append "other_file.js"
```

This means that the contents of the file "some\_file.js" will be added to the start of the code and the contents of "other\_file.js" 
will be added to the end of it. The paths given to `@codecat-prepend` and `@codecat-append` should be relative to the file they are 
being concatenated to.

Coffeescript works similarly:

```coffescript
# @codecat-prepend 'some_file.coffee'

# put main code here
result = doSomething()
if result.success
	alert('Congratulations!')
else
	alert('My condolences.')

# @codecat-append 'other_file.js'
```

These directives must appear on a line by themselves, but can be anywhere in the file. Regardless of where they appear, prepends will
always be added to the very beginning of the code in the order that they appear, and appends will always be added to the very end of
the code in the order that they appear. As such, it's probably best practice to either put all your prepends at the top and appends
at the bottom, or put all directives at the top.

"codecat" is the default prefix to use for directives but is customizable. This allows you to use "codekit" or "prepros" as a prefix
in order to process code created with these tools. Moreover, you can process a file multiple times with different prefixes to concatenate
different files at different points in a build process. For example, you could first concatenate other coffeescript files, compile that
coffeescript, then concatenate your javascript files to the result. That might look something like:

```coffeescript
###
// @js-prepend "some_lib.js"
###
# @coffee-prepend 'some_file.coffee'

# put main code here
result = doSomething()
if result.success
	alert('Congratulations!')
else
	alert('My condolences.')

# @coffee-append 'other_file.js'
###
// @js-append "other_lib.js"
###
```

Finally, you can specify the name of an installed node module instead of a file to concatenate it to the result:

`npm install some-module`

```javascript
// @codecat-prepend "some-module"
var result = doSomething();
```

Though, if you include a node module in this way, make sure it is web compatible. For example, if it `require`s
other modules, you might have to resort to something like webpack or browserify.

### Processing
To process files with CodeCat, first require it:

```javascript
var CodeCat = require('codecat');
```

Then create an instance for the file you want to process:

```javascript
var indexFile = new CodeCat("src/index.js");
```

You can pass an options object as a second argument, such as the file's `encoding` and the directive `prefix`:

```javascript
var indexFile = new CodeCat("src/index.js", {encoding: 'utf8', prefix: 'codekit'});
```

There are then two methods that you can then use to do the concatenation - `concat` and `concatTo`.

#### concat
`concat` accepts a callback that is called with a string result of the concatenation.

```javascript
indexFile.concat(function(concatStr) {
	console.log(concatStr);
});
```

This would log the result of the file concatentions (prepends and appends). Or with options:

```javascript
var options = {recursive: true, separator: "\n\n\n"};
indexFile.concat(options, function(concatStr) {
	console.log(concatStr);
});
```

#### concatTo
`concatTo` is like `concat`, but writes the result of the concatenation to a file or stream instead of
creating a string.

```javascript
indexFile.concatTo('dist/output.js', function(error) {
	if (error) console.error(error);
});
```

Or with a stream:

```javascript
indexFile.concatTo(writeStream, function(error) {
	if (error) console.error(error);
});
```

And with options:

```javascript
var options = {recursive: true, separator: "\n\n\n"};
indexFile.concatTo(writeStream, options, function(error) {
	if (error) console.error(error);
});
```

#### Options

##### recursive
The `recursive` option specifies whether or not to recursively concatenate files. In other words, if `recursive` is true,
then it will look for and prepend/append files for each prepended and appended file. If `recursive` is false, then it
will only check for and concatenate directives in the source file used to create the `CodeCat` instance.

Default is `false`

NOTICE: CodeCat does not check for circular references, so it's up to the user to make sure this doesn't happen. For example,
if file A includes file B, file B includes file C, and file C includes file A - then you're going to get an infinite recurse.

##### separator
The `separator` option specifies the string used to separate each concatenated file. So a separator of `"\n\n\n"` would put
three new lines between each prepended and appended file.

Default is `os.EOL`
