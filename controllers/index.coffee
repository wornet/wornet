'use strict'

command = require(__dirname + "/../core/system/command.js")

module.exports = (router) ->

	router.get '/push-hook', (req, res) ->

		command 'cd /var/www/nodejs/wornet/int'
		command 'git pull'
		command 'npm i'

		res.render 'index',
			executed: 'push-hook'