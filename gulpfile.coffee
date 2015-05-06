g = require "gulp"
lint = require "gulp-coffeelint"
plumber = require "gulp-plumber"
notify = require "gulp-notify"
mocha = require "gulp-mocha"

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
    mocha("reporter": "dot")
  )

g.task "default", ->
  g.watch "gulpfile.coffee", ["gulpfile-check"]
  g.watch [
    "tests/**/*.coffee"
    "src/**/*.coffee"
  ], ["test"]
