'use strict'

module.exports = (router) ->

	only = (list) ->
		(url, done) ->
			router.get url, (req, res) ->
				if req.user.email in list
					done (info) ->
						res.render 'admin/index', info: info
				else
					res.notFound()

	godOnly = only [
		'kylekatarnls@gmail.com'
	]

	adminOnly = only [
		'manuel.costes@gmail.com'
		'bastien.miclo@gmail.com'
		'kylekatarnls@gmail.com'
	]

	if config.env.development

		# login with any user
		router.get '/login/:hashedId', (req, res) ->
			id = cesarRight req.params.hashedId
			User.findById id, (err, user) ->
				auth.auth req, res, user
				res.redirect '/user/profile'

		# http links to https
		adminOnly '/users', (info) ->
			User.find (err, all) ->
				info if err
					err
				else
					ul = 'ul'
					for user in all
						ul += '\n\tli: a(href="/admin/login/' + user.hashedId + '") ' + user.email
					jd ul

	# http links to https
	adminOnly '/port', (info) ->
		info config.port

	adminOnly '/stats', (info) ->
		User.count (err, count) ->
			info 'Nombre d\'inscrits : ' + count + '<br>'

	# http links to https
	godOnly '/https', (info) ->
		count = 0
		success = 0
		failures = 0
		done = ->
			info success + ' / ' + (success + failures) + ' status modifiés : ' + failures + ' échecs'
		Status.find (err, statusList) ->
			for status in statusList
				modified = false
				for link in status.links
					if ! link.https and link.href.startWith 'static.wornet.fr/'
						link.href = 'www.' + link.href.substr ('static.').length
						link.https = true
						modified = true
				for image in status.images
					if image and image.src and image.src.startWith 'http://static.wornet.fr/'
						image.src = 'https://www.' + image.src.substr ('http://static.').length
						modified = true
				if status.content.contains 'http://static.wornet.fr'
					status.content = status.content.replace /http:\/\/static\.wornet\.fr\//g, 'https://www.wornet.fr/'
					modified = true
				if modified
					count++
					status.save (err) ->
						if err
							failures++
						else
							success++
						do done unless --count
			do done unless count
