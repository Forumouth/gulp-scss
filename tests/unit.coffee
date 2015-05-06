expect = require("chai").expect
sinon = require "sinon"

describe "SCSS unit test", ->
  objectToInject = undefined
  scss = undefined
  file = undefined
  func_scss = undefined
  cb = undefined
  ioMap = undefined

  before ->
    process.env.testing = true
    scss = require "../src/scss.coffee"

  beforeEach ->
    ioMap =
      "stdin": 0
      "stdout": 1
      "stderr": 2
    objectToInject =
      "spawn": sinon.stub().returns ioMap
    cb = sinon.spy()
    func_scss = scss.__compile__.invoke(objectToInject)
    file =
      "isNull": sinon.stub.returns(false)
      "isBuffer": sinon.stub.returns(true)
      "isStream": sinon.stub.returns(false)
      "pipe": sinon.spy()
      "path": "tests/data/source.scss"

  after ->
    delete process.env.testing
    delete require.cache[require.resolve "../src/scss.coffee"]

  it "Compile function should be an injectable function", ->
    expect(scss.__compile__.invoke).is.a "function"

  describe "Null File", ->
    beforeEach ->
      file.isNull = sinon.stub().returns(true)
      file.isBuffer = sinon.stub().returns(false)
    it "cb should returns as it is", ->
      func_scss()(file, undefined, cb)
      expect(cb.calledWith null, file).is.ok

  describe "When options are passed", ->
    describe "When bundleExec is true", ->
      func = undefined
      beforeEach ->
        func = func_scss "bundleExec": true
        func file, undefined, cb

      it "spawn function should be called with bundle exec scss", ->
        expect(
          objectToInject.spawn.calledWithExactly "bundle", [
            "exec"
            "scss"
          ]
        ).is.ok

      it "file should be piped to the stdin", ->
        expect(
          file.pipe.calledWithExactly ioMap.stdin, "end": true
        ).is.ok

      it "Callback should be called with file object", ->
        expect(cb.calledWith null, file).is.ok

      it "Path should have css extension", ->
        expect(file.path).is.equal "tests/data/source.css"

    describe "When bundleExec is false", ->
      func = undefined
      beforeEach ->
        func = func_scss "bundleExec": false
        func file, undefined, cb

      it "spawn function should be called with scss", ->
        expect(
          objectToInject.spawn.calledWithExactly "scss", []
        ).is.ok

      it "file should be piped to the stdin", ->
        expect(
          file.pipe.calledWithExactly ioMap.stdin, "end": true
        ).is.ok

      it "Callback should be called with file object", ->
        expect(cb.calledWith null, file).is.ok

      it "Path should have css extension", ->
        expect(file.path).is.equal "tests/data/source.css"

  describe "Without any options", ->
    func = undefined
    beforeEach ->
      func = func_scss()
      func file, undefined, cb

    it "spawn function should be called with scss", ->
      expect(
        objectToInject.spawn.calledWithExactly "scss", []
      ).is.ok

    it "file should be piped to the stdin", ->
      expect(
        file.pipe.calledWithExactly ioMap.stdin, "end": true
      ).is.ok

    it "Callback should be called with file object", ->
      expect(cb.calledWithExactly null, file).is.ok

    it "Path should have css extension", ->
      expect(file.path).is.equal "tests/data/source.css"


describe "For non-testing mode", ->
  after ->
    delete require.cache[require.resolve "../src/scss.coffee"]
  it "The plugin should be a function", ->
    expect(require "../src/scss.coffee").is.a "function"
