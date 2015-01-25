require __dirname + '/init'
command = require __dirname + '/../system/command.js'
command.sublimetext '.'
setTimeout ->
	command.open 'http://localhost:8000'
, 8000