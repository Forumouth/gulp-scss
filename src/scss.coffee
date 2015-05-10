inject = require("node-kissdi").inject
through = require "through2"
gutil = require "gulp-util"
merge = require "merge"
path = require "path"
testing = process.env.testing

compile = inject [
  "spawn"
  "vfs"
  (spawn, vfs) ->
    (opts) ->
      (file, enc, cb) ->
        if file.isNull()
          return cb null, file
        options =
          "bundleExec": false
          "sourcemap": "auto"
          "tmpPath": ".gulp-scss-cache"
        merge(options, opts)

        # Write file temporarily
        tmp = file.clone()
        tmp.pipe vfs.dest options.tmpPath

        file.path = gutil.replaceExtension file.path, ".css"
        command = []
        if options.bundleExec
          command = command.concat("bundle", "exec")
        command.push "scss"
        command = command.concat("--sourcemap=#{options.sourcemap}")

        proc = spawn command.splice(0, 1)[0], command
        file.pipe proc.stdin, "end": true
        file.contents = proc.stdout
        return cb null, file
], (
  "spawn": require("child_process").spawn
  "vfs": require("vinyl-fs")
)

module.exports = (options) -> through.obj compile.invoke()(options)

if testing
  module.exports.__compile__ = compile
