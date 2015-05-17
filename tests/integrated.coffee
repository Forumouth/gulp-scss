expect = require("chai").expect
fs = require "fs"
q = require "q"
g = require "gulp"
gutil = require "gulp-util"
sourcemaps = require "gulp-sourcemaps"
t = require "through2"
pathJoin = require("path").join

describe "SCSS integration tests", ->
  scss = require "../src/scss"
  describe "Single File Case", ->
    right = {}
    before (done) ->
      targetPromises = [
        q.nfcall(
          fs.readFile,
          "./tests/data/single/source.css"
        ).then(
          (css) -> right.file = css.toString("utf-8").trim()
        )
        q.nfcall(
          fs.readFile,
          "./tests/data/single/source.css.map"
        ).then(
          (map) -> right.sourcemap = JSON.parse(map.toString "utf-8")
        )
      ]
      q.all(targetPromises).done (-> done()), done
    after ->
      delete require.cache[require.resolve "../src/scss.coffee"]

    it "The file should be compiled properly", (done) ->
      compilationDefer = q.defer()
      g.src(
        "./tests/data/single/source.scss"
      ).pipe(
        sourcemaps.init()
      ).pipe(
        scss("bundleExec": true)
      ).pipe(
        sourcemaps.write("./", "includeContent": false)
      ).pipe(
        g.dest("./tests/results/single")
      ).once(
        "end",
        compilationDefer.resolve
      ).once("error", (e) ->
        compilationDefer.reject(e)
        throw e
      )

      compilationDefer.promise.then(
        -> q.all([
          q.nfcall fs.readFile, "./tests/results/single/source.css"
          q.nfcall fs.readFile, "./tests/results/single/source.css.map"
        ]).then(
          (data) ->
            expect(
              data[0].toString "utf-8"
            ).equal right.file
            expect(
              JSON.parse(data[1].toString "utf-8")
            ).eql right.sourcemap
        )
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
        q.all((
          q.nfcall(
            fs.readFile,
            pathJoin "tests/data/multiple", file
          ) for file in targetFiles
        )).then (results) ->
          results.forEach (result, index) ->
            if not right[pathJoin(
                "tests/results/multiple",
                targetFiles[index]
              )]
              right[pathJoin "tests/results/multiple", targetFiles[index]] = {}
            right[pathJoin(
              "tests/results/multiple",
              targetFiles[index]
            )].content = result.toString("utf-8").trim()
        q.all(
          (
              q.nfcall(
                fs.readFile,
                pathJoin("tests/data/multiple/#{file}.map")
              ) for file in targetFiles
          )
        ).then (results) ->
          results.forEach (result, index) ->
            if not right[pathJoin(
                "tests/results/multiple",
                targetFiles[index]
              )]
              right[pathJoin "tests/results/multiple", targetFiles[index]] = {}
            right[pathJoin(
              "tests/results/multiple",
              targetFiles[index]
            )].map = JSON.parse result
      ]
      q.all(promises).done (-> done()), done

    it "The files should be compiled properly", (done) ->
      defer = q.defer()
      g.src((
        pathJoin(
          "./tests/data/multiple",
          gutil.replaceExtension(file, ".scss")
        ) for file in targetFiles
      )).pipe(
        sourcemaps.init()
      ).pipe(
        scss "bundleExec": true
      ).pipe(
        sourcemaps.write("./", "includeContent": false)
      ).pipe(
        g.dest("./tests/results/multiple")
      ).once("end", defer.resolve).once("error", defer.reject)

      defer.promise.then(
        ->
          files = (pathJoin(
            "./tests/results/multiple",
            gutil.replaceExtension(file, ".css")
          ) for file in targetFiles)

          filePromises = []
          mapPromises = []
          files.forEach (file) -> filePromises.push q.nfcall(
            fs.readFile, file
          ).then(
            (data) ->
              expect(data.toString("utf-8").trim()).equal(
                right[file].content
              )
          )
          files.forEach (file) -> mapPromises.push q.nfcall(
            fs.readFile, file + ".map"
          ).then(
            (data) ->
              expect(JSON.parse data).eql(
                right[file].map
              )
          )
          q.all(
            filePromises.concat mapPromises
          ).catch((e) -> throw e).done (-> done()), done
      )
