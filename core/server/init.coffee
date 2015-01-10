
fs = require 'fs'
command = require __dirname + "/../system/command.js"

process.chdir __dirname + '/../..'

fs.exists 'mongod.lnk', (exists) ->
	if exists
		command 'mongod.lnk'

# Build coffee scripts
command 'coffee -bcw -o .build/js/ --join app public/js/app/'
command 'coffee -bcw -o .build/js/ --join test public/js/test/'
