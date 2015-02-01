'use strict'

logging = require 'gitlab-logging'

logging.configure
	host: 'http://gitlab.selfbuild.fr'
	user: 'autoreporter'
	token: 'H9bUs-NLqer7s9pHWETR'
	project_id: 3
	assignee_id: 2
	environment: 'production'

errors = {}

GitlabPackage =
	format: (error) ->
		strval error.stack || (error + '\n' + (new Error).stack)
	enabled: ->
		config.env.production
	issue: (error) ->
		if GitlabPackage.enabled()
			logging.handle GitlabPackage.format error
			console['log'] "Error issued"
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
			if errors[code].getLength() is config.wornet.errorsToIssue
				GitlabPackage.issue error
			console['log'] "Error recorded"

module.exports = GitlabPackage
