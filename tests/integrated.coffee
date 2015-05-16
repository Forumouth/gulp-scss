expect = require("chai").expect
fs = require "fs"
q = require "q"
g = require "gulp"
t = require "through2"

describe "SCSS integration tests", ->
  scss = require "../src/scss"
  describe "Single File Case", ->
    right = {}
    before ->
      right.file = fs.readFileSync(
        "./tests/data/single/correct.css"
      ).toString("utf-8").trim()
      right.sourcemap = JSON.parse(fs.readFileSync(
        "./tests/data/single/correct.css.map"
      ).toString("utf-8").trim())
    after ->
      delete require.cache[require.resolve "../src/scss.coffee"]

    it "The file should be compiled properly", (done) ->
      compilationDefer = q.defer()
      g.src(
        "./tests/data/single/source.scss"
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
      ).done (-> done()), done

  describe "Multiple Files Case", ->
    right = {}
    targetFiles = [
      "test1.css"
      "test2.css"
      "test3.css"
    ]
    beforeEach (done) ->
      promises = [
        q.all(
          (
            q.nfcall(
              fs.readFile,
              "tests/data/multiple/#{file}"
            ) for file in targetFiles
          )
        ).then (results) ->
          results.forEach (result, index) ->
            if not right[targetFiles[index]]
              right[targetFiles[index]] = {}
            right[targetFiles[index]].content = result.toString "utf-8"
        q.all(
          (
              q.nfcall(
                fs.readFile,
                "tests/data/multiple/#{map}"
              ) for map in ("#{targetFile}.map" for targetFile in targetFiles)
          )
        ).then (results) ->
          results.forEach (result, index) ->
            if not right[targetFiles[index]]
              right[targetFiles[index]] = {}
            right[targetFiles[index]].map = JSON.parse result
      ]
      q.all(promises).done (-> done()), done

    it "The files should be compiled properly", ->
      throw new Error "Not Implemented Yet!"
