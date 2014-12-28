'use strict'

nodemailer = require 'nodemailer'

smtpTransport = require 'nodemailer-smtp-transport'

errorMessage = 'Mailer not configured or not initialized'

transporter = null

MailPackage =

	init: ->
		if empty(config) or empty(config.wornet) or empty(config.wornet.mail) or empty(config.wornet.mail.auth.user)
			warn errorMessage
		else
			options =
				service: config.wornet.mail.service
				auth:
					user: config.wornet.mail.auth.user
					pass: config.wornet.mail.auth.pass
			if options.service is 'OVH'
				options = smtpTransport
				    host: 'localhost'
				    port: 465
				    auth: options.auth
			transporter = nodemailer.createTransport options

	send: (to, subject, text, html = null, from = null, done = null) ->
		if typeof html is 'function'
			if done is null
				html = html()
			else
				done = html
				html = null
		if typeof from is 'function'
			if done is null
				from = from()
			else
				done = from
				from = null

		if html is null
			html = text
				.replace /&/g, '&amp;'
				.replace /</g, '&lt;'
				.replace />/g, '&gt;'
				.replace /"/g, '&quot;'
				.replace /'/g, '&#039;'
				.replace /\n/g, '<br>'
		if from is null
			from = 'Wornet <contact@wornet.fr>'

		mailOptions =
			from: from
			to: to
			subject: subject
			text: text
			html: html

		if done is null
			done = (err, info) ->
				if config.wornet.mail.log
					if err
						console['log'] ["Send mail failed", mailOptions]
						warn err
					else
						console['log'] ["Send mail succeed", mailOptions]
						log info

		if transporter is null
			throw new Error errorMessage

		transporter.sendMail mailOptions, done

module.exports = MailPackage
