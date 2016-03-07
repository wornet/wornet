'use strict'

module.exports = (router) ->

	pm = new PagesManager router
		#.page '/newsroom'
		#.page '/jobs'
		.page '/static/legals'


	# Temporary fix of /undefined request
	router.get '/undefined', (req, res) ->
		res.end ''

	verifs = [
		'ba4b08bd2e99d09b297d0bf0b2a8d98c'
		'736d5c56306446a276790dc6a070a70a'
	]
	verifs.forEach (key) ->
		router.get '/' + key + '.txt', (req, res) ->
			res.end key

	if config.env.development
		# Client-side tests
		pm.page '/test', (req, res, done) ->
			User.remove email: $in: ['unit-test@selfbuild.fr', 'unit-test-login@selfbuild.fr'], ->
				User.create
					name:
						first: 'Good'
						last: 'Login'
					email: 'unit-test-login@selfbuild.fr'
					password: 'azer8Ty'
					role: 'confirmed'
					birthDate: (new Date).subYears 20
				, ->
					done {}
		# Store tests results
		router.post '/test/results', (req, res) ->
			functionExists = !! global.clitentSideUnitTestsCallback
			res.json functionExists: functionExists
			if functionExists
				clitentSideUnitTestsCallback req.body
		# Emulate a long pending with demanded time
		router.get '/pending/:time', (req, res) ->
			time = intval req.params.time
			delay time.seconds, ->
				res.json {}

		pm.page '/testfb', (req, res, done) ->
			res.render 'testfb',

	else
		router.get '/photos', (req, res) ->
			res.notFound()


	# When login/signin/profile page displays
	router.get '/', (req, res) ->
		if req.user
			# GET /
			UserPackage.renderHome req, res
		else
			# GET /user/login (and pre-signin)
			# Get errors in flash memory (any if AJAX is used and works on client device)
			res.render 'user/login',
				loginAlerts: req.getAlerts 'login' # Will be removed when errors will be displayed on the next step


	# Invite friends to join Wornet
	router.put '/invite', (req, res) ->
		req.flash 'profileSuccess', s("Invitations envoyées")
		res.redirect '/'
		delay 1, ->
			count = config.wornet.limits.mailsAtOnce
			req.body.emails.split(/\s*,\s*/g).each ->
				email = @
				Invitation.count email: email, (err, alreadyInvited) ->
					unless alreadyInvited
						if count--
							subject = s("{name} vous invite à rejoindre le réseau social WORNET", name: req.user.fullName)
							signinUrl = config.wornet.protocole +  '://' + req.getHeader 'host'
							signinUrl += '/user/signin/with/' + encodeURIComponent email
							message = jdMail 'invite', url: signinUrl
							MailPackage.send email, subject, message
							sended = new Date
						Invitation.create
							host: req.user.id
							email: email
							sended: sended
						, (err) ->
							if err
								warn err, req

	router.put '/contact', (req, res) ->
		res.json()
		delay 1, ->
			motif = req.data.motif
			message = req.data.message
			if motif and message
				emails = config.wornet.contact.emails[motif]
				subject = s("[{type}] Mail de contact de Wornet", type: req.data.motif)

				userInfos = getBrowserInformations req

				message = jdMail 'contact',
					motif: motif,
					message: message,
					email: req.user.email,
					browserName: userInfos.browser.name,
					browserVersion: userInfos.browser.version,
					osName: userInfos.os.name,
					osVersion: userInfos.os.version,
					cpu: userInfos.cpu.architecture,
					deviceName: userInfos.device.model,
					deviceVendor: userInfos.device.vendor,
					deviceType: userInfos.device.type

				MailPackage.send emails, subject, message

	# Report a non-appropriated content
	router.get '/report/:status', (req, res) ->
		if req.xhr
			res.json()
		else
			res.render 'report'
		id = req.params.status
		Status.findById id, (err, status) ->
			if status
				message = 'Un contenu a été signalé par ' + req.user.fullName + '. L\'id du contenu est : ' + id + '\nContenu :\n' + status.content
				MailPackage.send config.wornet.mail.reportTo, "[Wornet] Contenu signalé", message, (err, info) ->
					if err
						throw err
					else
						console['log'] info

	router.get '/:urlId', (req, res) ->
		urlId = req.params.urlId
		if urlId and /^[a-zA-Z0-9_.]*$/.test(urlId)
			isAPublicAccount req, urlId, false, (err, publicAccount, hashedId, user) ->
				if publicAccount or (user and user.accountConfidentiality is "private" and req.user)
					res.locals.friendAsked = req.flash 'friendAsked'
					UserPackage.renderProfile req, res, hashedId
				else
					res.redirect '/'
		else
			res.redirect '/'

	alias =
		'user/login': ''
		signin: 'user/signin'
		logout: 'user/logout'
		'forgotten-password': 'user/forgotten-password'
		profile: 'user/profile'

	for as, route of alias
		do (as, route) ->
			router.get '/' + as, (req, res) ->
				res.redirect '/' + route
