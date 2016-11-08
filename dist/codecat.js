// Generated by CoffeeScript 1.11.1
(function() {
  var CodeCat, EOL, Path, Readline, Writable, createReadStream, createWriteStream, readFileSync, ref,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  EOL = require('os').EOL;

  Readline = require('readline');

  ref = require('fs'), readFileSync = ref.readFileSync, createReadStream = ref.createReadStream, createWriteStream = ref.createWriteStream;

  Writable = require('stream').Writable;

  Path = require('path');

  module.exports = CodeCat = (function() {
    var callbackForEach, discernOptions, ensureStream, getSourceCommenter, isString, joinFiles, mapConcats, newRelative, regexpEscape;

    function CodeCat(source, options) {
      var commenter, encoding, getDirectiveRegExp, prefix, ref1, ref2, ref3;
      if (options == null) {
        options = {};
      }
      prefix = (ref1 = options.prefix) != null ? ref1 : 'codecat', commenter = (ref2 = options.commenter) != null ? ref2 : getSourceCommenter(source), encoding = (ref3 = options.encoding) != null ? ref3 : 'utf8';
      getDirectiveRegExp = function(directive) {
        return new RegExp("^\\s*" + commenter + "\\s*@" + prefix + "-" + directive + "\\s+([\"']?)(.+?)\\1(\\s|$)");
      };
      Object.defineProperties(this, {
        source: {
          value: source
        },
        prefix: {
          value: prefix
        },
        encoding: {
          value: encoding
        },
        prependRegexp: {
          value: getDirectiveRegExp('prepend')
        },
        appendRegexp: {
          value: getDirectiveRegExp('append')
        },
        Relative: {
          value: (function(superClass) {
            extend(_Class, superClass);

            function _Class(src) {
              var relSrc, sourceDir;
              sourceDir = Path.dirname(source);
              relSrc = Path.join(sourceDir, src);
              _Class.__super__.constructor.call(this, relSrc, options);
            }

            return _Class;

          })(CodeCat)
        }
      });
    }

    CodeCat.prototype.findConcats = function(options, callback) {
      var append, concats, lineReader, prepend, ref1, ref2;
      ref1 = discernOptions(options, callback), options = ref1[0], callback = ref1[1];
      ref2 = concats = {
        prepend: [],
        append: []
      }, prepend = ref2.prepend, append = ref2.append;
      lineReader = Readline.createInterface({
        input: createReadStream(this.source, {
          encoding: this.encoding
        })
      });
      lineReader.on('line', (function(_this) {
        return function(line) {
          var match, ref3, ref4;
          if (match = (ref3 = line.match(_this.prependRegexp)) != null ? ref3[2] : void 0) {
            return prepend.push(match);
          } else if (match = (ref4 = line.match(_this.appendRegexp)) != null ? ref4[2] : void 0) {
            return append.push(match);
          }
        };
      })(this));
      return lineReader.on('close', function() {
        return typeof callback === "function" ? callback(concats) : void 0;
      });
    };

    CodeCat.prototype.concat = function(options, callback) {
      var concatted, ref1, stream, write;
      ref1 = discernOptions(options, callback), options = ref1[0], callback = ref1[1];
      concatted = '';
      write = function(chunk, encoding, cb) {
        concatted += chunk;
        return typeof cb === "function" ? cb(null) : void 0;
      };
      stream = new Writable({
        write: write
      });
      return this.concatTo(stream, options, function(error) {
        return typeof callback === "function" ? callback(concatted) : void 0;
      });
    };

    CodeCat.prototype.concatTo = function(dest, options, callback) {
      var recursive, ref1, ref2;
      ref1 = discernOptions(options, callback), options = ref1[0], callback = ref1[1];
      recursive = (ref2 = options.recursive) != null ? ref2 : true;
      return ensureStream(dest, {
        defaultEncoding: this.encoding
      }, (function(_this) {
        return function(stream, end) {
          return _this.findConcats(function(concats) {
            var error, paths;
            error = null;
            if (recursive) {
              concats = mapConcats(concats, newRelative, _this);
            }
            paths = slice.call(concats.prepend).concat([_this.source], slice.call(concats.append));
            return joinFiles(paths, _this.encoding, stream, options, function() {
              return typeof callback === "function" ? callback(error) : void 0;
            });
          });
        };
      })(this));
    };

    CodeCat.Commenters = {
      '': '//',
      js: '//',
      coffee: '#'
    };

    getSourceCommenter = function(source) {
      var commenter, ext;
      ext = Path.extname(source).slice(1);
      commenter = CodeCat.Commenters[ext];
      if (commenter != null) {
        return regexpEscape(commenter);
      } else {
        return '';
      }
    };

    newRelative = function(source) {
      return new this.Relative(source);
    };

    joinFiles = function(files, encoding, stream, options, finishedFn) {
      var ref1, separator;
      if (options == null) {
        options = {};
      }
      separator = (ref1 = options.separator) != null ? ref1 : EOL;
      return callbackForEach(files, finishedFn, function(file, notFirst, done) {
        var output, writeEndCb;
        output = (notFirst && separator) || '';
        writeEndCb = file instanceof CodeCat ? function() {
          return file.concatTo(stream, options, done);
        } : (output += readFileSync(file, {
          encoding: encoding
        }), done);
        return stream.write(output, encoding, writeEndCb);
      });
    };

    ensureStream = function(dest, options, fn) {
      var end, ref1, stream;
      ref1 = discernOptions(options, fn), options = ref1[0], fn = ref1[1];
      if (isString(dest)) {
        stream = createWriteStream(dest, options);
        end = function(endCb) {
          return stream.end(endCb);
        };
        return stream.once('open', function() {
          return fn(stream, end);
        });
      } else {
        end = function(endCb) {
          return typeof endCb === "function" ? endCb() : void 0;
        };
        return fn(dest, end);
      }
    };

    mapConcats = function(concats, map, thisArg) {
      var files, mapped, type;
      mapped = {};
      for (type in concats) {
        if (!hasProp.call(concats, type)) continue;
        files = concats[type];
        mapped[type] = files.map(map, thisArg);
      }
      return mapped;
    };

    regexpEscape = function(str) {
      return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&');
    };

    isString = function(val) {
      return (typeof val === 'string') || (val instanceof String);
    };

    discernOptions = function(options, fn) {
      if (options instanceof Function) {
        return [{}, options];
      } else {
        return [options != null ? options : {}, fn];
      }
    };

    callbackForEach = function(collection, done, callback) {
      var callbackCurrent, current, ref1, total;
      ref1 = [collection.length, 0], total = ref1[0], current = ref1[1];
      return (callbackCurrent = function() {
        var called, item;
        item = collection[current];
        called = false;
        return callback(item, current, function(error) {
          if (error != null) {
            console.error(error);
          }
          if (!called) {
            called = true;
            if (++current >= total) {
              return done();
            } else {
              return callbackCurrent();
            }
          }
        });
      })();
    };

    return CodeCat;

  })();

}).call(this);
