'use strict'

module.exports = (router) ->


	pm = new PagesManager router
		.page '/newsroom'
		.page '/jobs'
		.page '/legals'


	# Temporary fix of /undefined request
	router.get '/undefined', (req, res) ->
		res.end ''

	router.get '/ba4b08bd2e99d09b297d0bf0b2a8d98c.txt', ->
		res.end 'ba4b08bd2e99d09b297d0bf0b2a8d98c'

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
								warn err


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
