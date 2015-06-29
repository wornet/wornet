'use strict'

onready = require './test'
fs = require 'fs'
exec = require("child_process").exec

xdescribe "current package version", ->

	@timeout 10.seconds

	it "should not be already tagged", (done) ->
		pack = require __dirname + '/../package.json'
		child = exec("git ls-remote --tags");
		child.unref();
		content = ''
		child.stdout.on 'data', (data) ->
			content += data.toString()
		child.stderr.on 'data', (data) ->
			content += data.toString()
		child.on 'exit', ->
			success = !! content.length
			success.should.be.true "no error thrown"
			reg = new RegExp '\\srefs/tags/' + pack.version + '\\n', 'ig'
			hasRef = reg.test content || ''
			hasRef.should.be.false "current version in not in the refs"
			done()
