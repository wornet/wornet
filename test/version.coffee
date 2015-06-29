'use strict'

onready = require './test'
fs = require 'fs'

xdescribe "current package version", ->

	@timeout 10.seconds

	it "should not be already tagged", (done) ->
		pack = require __dirname + '/../package.json'
		fs.readFile __dirname + '/../.git/info/refs', (err, content) ->
			success = ! err
			success.should.be.true "no error thrown"
			reg = new RegExp '\\srefs/tags/' + pack.version + '\\n', 'ig'
			hasRef = reg.test content || ''
			hasRef.should.be.false "current version in not in the refs"
			done()
