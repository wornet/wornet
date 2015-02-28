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
		Status.all (err, statusList) ->
			for status in statusList
				modified = false
				if ! status.https and status.href.startWith 'static.wornet.fr/'
					status.href = status.href.replace /^static\./, 'www.'
					status.https = true
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
