g = require "gulp"
lint = require "gulp-coffeelint"
plumber = require "gulp-plumber"
notify = require "gulp-notify"
mocha = require "gulp-mocha"
coffee = require "gulp-coffee"

g.task "gulpfile-check", ->
  g.src(
    "gulpfile.coffee"
  ).pipe(
    plumber("errorHandler": notify.onError("<%= error.message %>"))
  ).pipe(
    lint("coffeelint.json")
  ).pipe(
    lint.reporter()
  ).pipe(
    lint.reporter("failOnWarning")
  )

g.task "test", ->
  g.src(
    "tests/**/*.coffee"
  ).pipe(
    plumber("errorHandler": notify.onError("<%= error.message %>"))
  ).pipe(
    lint()
  ).pipe(
    lint.reporter()
  ).pipe(
    lint.reporter("failOnWarning")
  ).pipe(
    mocha(
      "reporter": "dot"
      "timeout": 2000
    )
  )

g.task "compile", ["test"], ->
  g.src("src/**/*.coffee").pipe(coffee()).pipe(g.dest("./lib"))

g.task "default", ->
  g.watch "gulpfile.coffee", ["gulpfile-check"]
  g.watch [
    "tests/**/*.coffee"
    "src/**/*.coffee"
  ], ["compile"]
