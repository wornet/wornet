'use strict'

root = __dirname + '/../../'
config = require root + 'config/config.json'
autoloadDirectories = config.wornet.autoloadDirectories

extend = require 'extend'
glob = require 'glob'
mongoose = require 'mongoose'
global.Schema = mongoose.Schema
global.ObjectId = Schema.ObjectId

# Get functions
functions = require root + 'core/utils/functions'

# Make functions and config usables in controllers and other stuff
extend global, functions

defer = []

# Load all files contained in autoloadDirectories
pendingDirectories = autoloadDirectories.length
next = ->
	# When no more directory need to be loaded
	defer.forEach (callback) ->
		callback autoloadDirectories
autoloadDirectories.forEach (directory) ->
	glob directory + "/**/*.coffee", (er, files) ->
		pendingFiles = files.length
		if pendingFiles
			files.forEach (file) ->
				loadedValue = require root + file
				if typeof(loadedValue.name) is 'undefined' || empty(loadedValue.name)
					name = file.substr(directory.length + 1).replace(/\.[^\.]+$/g, '')
				else
					name = loadedValue.name
				if global[name]?
					console.warn name + ' variable already declared'
				else
					global[name] = loadedValue
					if name.length > 6 && name.substr(-6) is 'Schema'
						model name.substr 0, name.length - 6, loadedValue

				unless --pendingFiles
					unless --pendingDirectories
						next()
		else
			unless --pendingDirectories
				next()

module.exports = (callback) ->

	if pendingDirectories
		defer.push callback
	else
		callback autoloadDirectories