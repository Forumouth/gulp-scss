(function() {
  var compile, gutil, inject, testing, through;

  inject = require("node-kissdi").inject;

  through = require("through2");

  gutil = require("gulp-util");

  testing = process.env.testing;

  compile = inject([
    "spawn", function(spawn) {
      return function(options) {
        return function(file, enc, cb) {
          var command, proc;
          if (file.isNull()) {
            cb(null, file);
          }
          file.path = gutil.replaceExtension(file.path, ".css");
          command = [];
          if (options) {
            if (options.bundleExec) {
              command = command.concat("bundle", "exec");
            }
          }
          command.push("scss");
          proc = spawn(command.splice(0, 1)[0], command);
          file.pipe(proc.stdin, {
            "end": true
          });
          file.contents = proc.stdout;
          return cb(null, file);
        };
      };
    }
  ], {
    "spawn": require("child_process").spawn
  });

  module.exports = function(options) {
    return through.obj(compile.invoke()(options));
  };

  if (testing) {
    module.exports.__compile__ = compile;
  }

}).call(this);
