'use strict'

module.exports = (router) ->

	adminOnly = (url, done) ->
		router.get url, (req, res) ->
			if req.user.email is 'kylekatarnls@gmail.com'
				done (info) ->
					res.render 'admin/index', info: info
			else
				res.notFound()

	# http links to https
	adminOnly '/port', (info) ->
		info config.port

	# http links to https
	adminOnly '/https', (info) ->
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
						link.href = link.href.replace /^static\./, 'www.'
						link.https = true
						modified = true
				for image in status.images
					if image and image.src and image.src.startWith 'http://static.wornet.fr/'
						image.src = image.src.replace /^http://static\./, 'https://www.'
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
