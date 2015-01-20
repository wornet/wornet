'use strict'

autoloadDirectories = config.wornet.autoloadDirectories

global.extend = require 'extend'
global.glob = require 'glob'
global.mongoose = require 'mongoose'
global.Schema = mongoose.Schema
global.ObjectId = Schema.ObjectId


# Extends RegExp class
require coreDir + 'utils/RegExpString'


defer = []
models = []

# Load all files contained in autoloadDirectories
pendingDirectories = autoloadDirectories.length
next = ->
	# When no more directory need to be loaded
	models.forEach (params) ->
		model params[0], params[1]
	defer.forEach (callback) ->
		callback autoloadDirectories

autoloadDirectories.forEach (directory) ->
	glob directory + "/**/*.coffee", (er, files) ->
		pendingFiles = files.length
		if pendingFiles
			files.forEach (file) ->
				loadedValue = require rootDir + file
				if typeof(loadedValue.name) is 'undefined' || empty(loadedValue.name)
					name = file.substr(directory.length + 1).replace(/\.[^\.]+$/g, '')
				else
					name = loadedValue.name
				unless global[name]?
					global[name] = loadedValue
					# If the file is a Schema
					if name.length > 6 && name.substr(-6) is 'Schema' and loadedValue instanceof Schema
						# Create the corresponding Model
						models.push [name.substr(0, name.length - 6), loadedValue]

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
