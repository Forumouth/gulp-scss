(function() {
  var applySourceMap, compile, gutil, inject, mapConverter, merge, path, q, testing, through;

  inject = require("node-kissdi").inject;

  through = require("through2");

  gutil = require("gulp-util");

  merge = require("merge");

  path = require("path");

  q = require("q");

  mapConverter = require("convert-source-map");

  testing = process.env.testing;

  applySourceMap = require("vinyl-sourcemaps-apply");

  compile = inject([
    "exec", "mkdirp", "fs", function(exec, mkdirp, fs) {
      return function(opts) {
        return function(file, enc, cb) {
          var compilerPromise, options, tmpDir;
          if (file.isNull()) {
            return cb(null, file);
          }
          options = {
            "bundleExec": false,
            "sourcemap": "auto",
            "tmpPath": ".gulp-scss-cache"
          };
          merge(options, opts);
          tmpDir = path.join(file.cwd, options.tmpPath, path.relative(file.cwd, file.base), path.dirname(file.relative));
          compilerPromise = q.defer();
          q.nfcall(mkdirp, tmpDir).then(function() {
            var defer, tmp, tmpWriteStream;
            defer = q.defer();
            tmp = file.clone();
            tmpWriteStream = fs.createWriteStream(path.join(tmpDir, path.basename(tmp.relative)));
            tmpWriteStream.on("finish", defer.resolve);
            tmpWriteStream.on("error", defer.reject);
            tmp.pipe(tmpWriteStream, {
              "end": true
            });
            return defer.promise;
          }).then(function() {
            var command, defer, proc;
            defer = q.defer();
            command = [];
            if (options.bundleExec) {
              command = command.concat("bundle", "exec");
            }
            command.push("scss");
            command = command.concat(["--sourcemap=" + options.sourcemap, path.join(tmpDir, path.basename(file.relative)), path.join(tmpDir, gutil.replaceExtension(path.basename(file.relative), ".css"))]);
            proc = exec(command.join(" "));
            proc.on("error", defer.reject);
            proc.on("close", defer.resolve);
            return defer.promise;
          }).then(function() {
            var contents, sourcemap;
            file.path = gutil.replaceExtension(file.path, ".css");
            contents = fs.readFileSync(path.join(tmpDir, gutil.replaceExtension(path.basename(file.relative), ".css"))).toString("utf-8");
            sourcemap = mapConverter.fromMapFileSource(contents, tmpDir);
            if (sourcemap) {
              applySourceMap(file, sourcemap.sourcemap);
            }
            file.contents = new Buffer(mapConverter.removeMapFileComments(contents).trim());
            cb(null, file);
            return compilerPromise.resolve();
          })["catch"](function(e) {
            var error;
            error = new gutil.PluginError("gulp-scss", "Compilation failed.: " + e + "\nStack Trace:\n" + e.stack);
            compilerPromise.reject(error);
            cb(error);
            throw error;
          });
          return compilerPromise.promise;
        };
      };
    }
  ], {
    "exec": require("child_process").exec,
    "mkdirp": require("mkdirp"),
    "fs": require("fs")
  });

  module.exports = function(options) {
    return through.obj(compile.invoke()(options));
  };

  if (testing) {
    module.exports.__compile__ = compile;
  }

}).call(this);
