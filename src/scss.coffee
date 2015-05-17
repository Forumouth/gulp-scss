inject = require("node-kissdi").inject
through = require "through2"
gutil = require "gulp-util"
merge = require "merge"
path = require "path"
q = require "q"
mapConverter = require "convert-source-map"
testing = process.env.testing
applySourceMap = require "vinyl-sourcemaps-apply"

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
        tmpDir = path.join(
          file.cwd,
          options.tmpPath,
          path.relative(file.cwd, file.base),
          path.dirname(file.relative)
        )

        compilerPromise = q.defer()
        q.nfcall(mkdirp, tmpDir).then(
          ->
            defer = q.defer()
            tmp = file.clone()
            tmpWriteStream = fs.createWriteStream(
              path.join tmpDir, tmp.relative
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
            command = command.concat([
              "--sourcemap=#{options.sourcemap}"
              path.join tmpDir, file.relative
              path.join tmpDir, gutil.replaceExtension file.relative, ".css"
            ])

            proc = exec command.join(" ")
            proc.on "error", defer.reject
            proc.on "close", defer.resolve
            return defer.promise
        ).then(
          ->
            file.path = gutil.replaceExtension file.path, ".css"
            # I want to pass readable stream, but I don't.
            # Why? Almost all gulp plugins don't support stream!
            contents = fs.readFileSync(
               path.join tmpDir, gutil.replaceExtension file.relative, ".css"
            ).toString("utf-8")
            sourcemap = mapConverter.fromMapFileSource contents, tmpDir

            if sourcemap
              applySourceMap file, sourcemap.sourcemap
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
