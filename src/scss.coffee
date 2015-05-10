inject = require("node-kissdi").inject
through = require "through2"
gutil = require "gulp-util"
testing = process.env.testing

compile = inject [
  "spawn",
  (spawn) ->
    (options) ->
      (file, enc, cb) ->
        if file.isNull()
          return cb null, file
        file.path = gutil.replaceExtension file.path, ".css"
        command = []
        if options
          if options.bundleExec
            command = command.concat("bundle", "exec")
        command.push "scss"
        proc = spawn command.splice(0, 1)[0], command
        file.pipe proc.stdin, "end": true
        file.contents = proc.stdout
        return cb null, file
], "spawn": require("child_process").spawn

module.exports = (options) -> through.obj compile.invoke()(options)

if testing
  module.exports.__compile__ = compile
