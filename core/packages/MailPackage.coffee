'use strict'

nodemailer = require 'nodemailer'

transporter = nodemailer.createTransport
	service: config.wornet.mail.service
	auth:
		user: config.wornet.mail.auth.user
		pass: config.wornet.mail.auth.pass
	config.wornet.mail

MailPackage =
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

		transporter.sendMail mailOptions, done

module.exports = MailPackage
