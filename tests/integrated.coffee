expect = require("chai").expect
fs = require "fs"
q = require "q"
g = require "gulp"
t = require "through2"

describe "SCSS integration tests", ->
  right = undefined
  scss = require "../src/scss"
  before ->
    right = fs.readFileSync("./tests/data/correct.css").toString()
  after ->
    delete require.cache[require.resolve "../src/scss.coffee"]

  it "The file should be compiled properly", (done) ->
    g.src(
      "./tests/data/source.scss"
    ).pipe(
      scss("bundleExec": true)
    ).pipe(t.obj (file, enc, cb) ->
      result = []
      file.contents.on "data", (chunk) -> result.push chunk.toString()
      file.contents.on "end", ->
        result = result.join()
        expect(result).is.equal right
        done()
        cb null, file
      file.contents.read()
    ).once "error", done
