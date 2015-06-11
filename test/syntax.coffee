'use strict'

onready = require './test'
fs = require 'fs'

describe "syntax", ->

	@timeout 10.seconds

	files = []
	filesContents = {}

	fileGetContents = (file, done) ->
		if filesContents[file]
			done null, filesContents[file]
		else
			fs.readFile file, done

	allFiles = (done, test) ->
		count = files.length
		files.forEach (file) ->
			fileGetContents file, (err, contents) ->
				(err is null).should.equal true, "readFile should not throw " + err
				if contents
					test file, contents, ->
						unless --count
							done()

	forEachFile = (test) ->
		(done) ->
			allFiles done, (file, contents, done) ->
				test file.replace(/^.+\.\./, ''), contents
				done()

	before (done) ->
		glob __dirname + "/../**/*.coffee", (err, inputFiles) ->
			files = inputFiles
				.filter (file) ->
					! /[\/\\]?node_modules[\/\\]/.test file.replace(/^.+\.\./, '')
			done()

	describe "coffee files", ->

		it "must be at least 10 coffee files", ->
			files.length.should.be.above 10

		logOrConsoleLog = "lo" + "g or console.lo" + "g"
		it "should not contains " + logOrConsoleLog, forEachFile (file, contents) ->
			/[^a-zA-Z0-9_]console\.log[^a-zA-Z0-9_]/.test(contents).should.equal false, file + " should not contains " + logOrConsoleLog
