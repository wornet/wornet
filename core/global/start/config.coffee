'use strict'

deepextend = require 'deep-extend'

getConfig = (name) ->
	try
		config = require __dirname + '/../../../config/' + name + '.json'
	catch e
	config || {}

module.exports = (env, port) ->

	port = parseInt port

	if isNaN(port) or port < 1
		port = 8000

	config = port: port

	global.mainConfig = getConfig 'config'
	global.customConfig = getConfig 'custom'
	global.envConfig = getConfig env

	deepextend config, mainConfig
	deepextend config, envConfig
	deepextend config, customConfig

	config.env ||= {}

	config
