'use strict'

root = __dirname + '/../../'
config = require root + 'config/config.json'
autoloadDirectories = config.wornet.autoloadDirectories

extend = require 'extend'
glob = require 'glob'
mongoose = require 'mongoose'
Schema = mongoose.Schema

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
			if global[name]?
				console.warn name + ' variable already declared'
			else
				global[name] = loadedValue
				if name.length > 6 && name.substr(-6) is 'Schema'
					modelName = name.substr 0, name.length - 6
					model = mongoose.model modelName, loadedValue
					if global[modelName]? || global[modelName + 'Model']?
						throw modelName + ' model already token'
					global[modelName] = model
					global[modelName + 'Model'] = model

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