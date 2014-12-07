'use strict'

nodemailer = require 'nodemailer'

errorMessage = 'Mailer not configured or not initialized'

transporter = null

MailPackage =

	init: ->
		if empty(config) or empty(config.wornet) or empty(config.wornet.mail) or empty(config.wornet.mail.auth.user)
			warn errorMessage
		else
			transporter = nodemailer.createTransport
				service: config.wornet.mail.service
				auth:
					user: config.wornet.mail.auth.user
					pass: config.wornet.mail.auth.pass
				config.wornet.mail

	send: (to, subject, text, html = null, from = null, done = null) ->
		if done is null
			done = from
			from = null
			if done is null
				done = html
				html = null
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

		if transporter is null
			throw new Error errorMessage

		transporter.sendMail mailOptions, done

module.exports = MailPackage
