'use strict'

logging = require 'gitlab-logging'

host = 'http://gitlab.selfbuild.fr'

path = 'master'

fs.readFile __dirname + '/../../.git/HEAD', (err, contents) ->
	if contents and ! contents.contains 'refs/heads/master'
		path = contents

logging.configure
	host: host
	user: 'autoreporter'
	token: 'H9bUs-NLqer7s9pHWETR'
	project_id: 3
	assignee_id: 2
	environment: config.wornet.env || 'production'

errors = {}

GitlabPackage =
	format: (error) ->
		strval config.wornet.version + ': ' + error + '\n' +
			(error.stack || (new Error).stack).replace /\/home\/[^\/]+\/([^:]+):[0-9]+:/g, (all, file, line) ->
				'<a href="' + host + '/kylek/wornet/blob/' + path + '/' + file + '#L' + line + '">' + all + ':</a>'
	enabled: ->
		config.env.production
	issue: (error) ->
		if GitlabPackage.enabled()
			logging.handle GitlabPackage.format error
			#console['log'] "Error issued:"
			#console['warn'] error
	error: (error) ->
		if GitlabPackage.enabled()
			error = GitlabPackage.format error
			code = sha1 error
			if errors[code]
				for err, k of errors[code]
					if k < Date.yesterday().getTime()
						delete errors[code]
			else
				errors[code] = {}
			errors[code][time()] = error
			# if errors[code].getLength() is config.wornet.errorsToIssue
			GitlabPackage.issue error
			#console['log'] "Error recorded:"
			#console['warn'] error

module.exports = GitlabPackage
