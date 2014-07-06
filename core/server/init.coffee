
fs = require 'fs'
command = require __dirname + "/../system/command.js"

process.chdir __dirname + '/../..'

fs.exists 'mongod.lnk', (exists) ->
	if exists
		command 'mongod.lnk'

# Build coffee scripts
command 'coffee -b -o .build/js -wc public/js'