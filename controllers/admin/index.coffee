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

	stats = (sortColumn) ->
		(info) ->
			User.count (err, count) ->
				Counter.find email: $in: ['unsubscribe', 'resubscribe'], (err, counters) ->
					exactAge = $divide: [$subtract: [new Date, "$birthDate"], 31558464000]
					match = $match: birthDate: $exists: true
					project = $project:
						age: $subtract: [exactAge, $mod: [exactAge, 1]]
					group = $group:
						_id: "$age"
						count: $sum: 1
					sort = $sort: sortColumn
					User.aggregate [
						match
						project
						group
						sort
					], (err, ages) ->
						if err
							info err
						else unless ages
							info "ages is empty"
						else
							nbUsers = 'Nombre d\'inscrits'
							unsub = counters.findOne name: 'unsubscribe'
							unsub = if unsub then unsub.count else 0
							resub = counters.findOne name: 'resubscribe'
							resub = if resub then resub.count else 0
							sum = 0
							total = 0
							table = (
								for age in ages
									sum += age.count
									total += age._id * age.count
									'\n\ttr' +
									'\n\t\ttd ' + age._id +
									'\n\t\ttd ' + age.count
							).join ''
							age = strval (Math.round 10 * total / sum) / 10
							info jd 'p\n\t| ' + nbUsers + ' : ' + count +
								'\np\n\t| Désinscriptions : ' + unsub +
								'\np\n\t| Résinscriptions : ' + resub +
								'\np\n\t| Âge moyen : ' + (age.replace '.', ',') +
								'\ntable' +
								'\n\ttr' +
								'\n\t\tth: a(href="/admin/stats/ages")!="Âge &nbsp; &nbsp;"' +
								'\n\t\tth: a(href="/admin/stats") ' + nbUsers +
								table

	adminOnly '/stats', stats count: -1

	adminOnly '/stats/ages', stats _id: 1

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
