'use strict'

root = __dirname + '/../../'
config = require root + 'config/config.json'
autoloadDirectories = config.wornet.autoloadDirectories

extend = require 'extend'
glob = require 'glob'

# Get functions
functions = require root + 'core/utils/functions'

# Make functions and config usables in controllers and other stuff
extend global, functions


# Load all files contained in autoloadDirectories
pending = autoloadDirectories.length
autoloadDirectories.forEach (directory) ->
	glob directory + "/**/*.coffee", (er, files) ->
		files.forEach (file) ->
			loadedValue = require root + file
			if typeof(loadedValue.name) is 'undefined' || empty(loadedValue.name)
				name = file.substr(directory.length + 1).replace(/\.[^\.]+$/g, '')
			else
				name = loadedValue.name
			global[name] = loadedValue unless global[name]?

		# When no more directory need to be loaded
		unless --pending
			defer.forEach (callback) ->
				callback autoloadDirectories

defer = []

module.exports = (callback) ->

	if pending
		defer.push callback
	else
		callback autoloadDirectories