expect = require("chai").expect
fs = require "fs"
q = require "q"
g = require "gulp"
t = require "through2"

describe "SCSS integration tests", ->
  right = {}
  scss = require "../src/scss"
  before ->
    right.file = fs.readFileSync(
      "./tests/data/correct.css"
    ).toString("utf-8").trim()
    right.sourcemap = JSON.parse(fs.readFileSync(
      "./tests/data/correct.css.map"
    ).toString("utf-8").trim())
  after ->
    delete require.cache[require.resolve "../src/scss.coffee"]

  it "The file should be compiled properly", (done) ->
    compilationDefer = q.defer()
    g.src(
      "./tests/data/source.scss"
    ).pipe(
      scss("bundleExec": true)
    ).pipe(t.obj (file, enc, cb) ->
      compilationDefer.resolve(file)
      cb null, file
    ).once "error", (e) ->
      compilationDefer.reject(e)
      throw e

    compilationDefer.promise.then(
      (file) ->
        expect(file.contents.toString("utf-8")).is.equal right.file
        expect(file.sourceMap).is.eql right.sourcemap
    ).catch((e) -> throw e).done (-> done()), done
