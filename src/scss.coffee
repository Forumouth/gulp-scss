inject = require("node-kissdi").inject
through = require "through2"
gutil = require "gulp-util"
merge = require "merge"
path = require "path"
q = require "q"
mapConverter = require "convert-source-map"
testing = process.env.testing

compile = inject [
  "exec"
  "mkdirp"
  "fs"
  (exec, mkdirp, fs) ->
    (opts) ->
      (file, enc, cb) ->
        if file.isNull()
          return cb null, file
        options =
          "bundleExec": false
          "sourcemap": "auto"
          "tmpPath": ".gulp-scss-cache"
        merge(options, opts)

        compilerPromise = q.defer()
        q.nfcall(mkdirp, options.tmpPath).then(
          ->
            defer = q.defer()
            tmp = file.clone()
            tmpWriteStream = fs.createWriteStream(
              path.join options.tmpPath, tmp.relative
            )
            tmpWriteStream.on "finish", defer.resolve
            tmpWriteStream.on "error", defer.reject
            tmp.pipe tmpWriteStream, "end": true
            return defer.promise
        ).then(
          ->
            defer = q.defer()
            command = []
            if options.bundleExec
              command = command.concat "bundle", "exec"
            command.push "scss"
            command = command.concat(
              "--sourcemap=#{options.sourcemap}",
              path.join(
                options.tmpPath,
                file.relative
              ),
              path.join(
                options.tmpPath,
                gutil.replaceExtension file.relative, ".css"
              )
            )

            proc = exec command.join(" ")
            proc.on "error", defer.reject
            proc.on "close", defer.resolve
            return defer.promise
        ).then(
          ->
            file.path = path.join(
              options.tmpPath, gutil.replaceExtension file.relative, ".css"
            )
            # I want to pass readable stream, but I don't.
            # Why? Almost all gulp plugins don't support stream!
            contents = fs.readFileSync(file.path).toString("utf-8")
            sourcemap = mapConverter.fromMapFileSource(
              contents, options.tmpPath
            )
            file.contents = new Buffer(
              mapConverter.removeMapFileComments(contents).trim()
            )
            cb null, file
            compilerPromise.resolve()
        ).catch(
          (e) ->
            error = new gutil.PluginError(
              "gulp-scss",
              "Compilation failed.: #{e}\nStack Trace:\n#{e.stack}"
            )
            compilerPromise.reject error
            throw error
        )
        return compilerPromise.promise
], (
  "exec": require("child_process").exec
  "mkdirp": require "mkdirp"
  "fs": require("fs")
)

module.exports = (options) -> through.obj compile.invoke()(options)

if testing
  module.exports.__compile__ = compile
