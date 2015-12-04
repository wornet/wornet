'use strict'

module.exports = (router) ->

	only = (list) ->
		(url, done) ->
			router.get url, (req, res) ->
				if req.user.email in list
					done (info) ->
						res.render 'admin/index', info: info
					, req, res
				else
					res.notFound()

	godOnly = only [
		'kylekatarnls@gmail.com'
		'jeremy.bayle87@hotmail.fr'
		'jeremy.bayle@wornet.fr'
	]

	adminOnly = only [
		'manuel.costes@gmail.com'
		'bastien.miclo@gmail.com'
		'kylekatarnls@gmail.com'
		'jeremy.bayle87@hotmail.fr'
		'jeremy.bayle@wornet.fr'
	]

	if config.env.development

		# login with any user
		router.get '/login/:hashedId', (req, res) ->
			id = cesarRight req.params.hashedId
			User.findById id, (err, user) ->
				auth.auth req, res, user
				res.redirect '/' + user.uniqueURLID

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
	adminOnly '/', (info, req, res) ->
		res.render 'admin/menu'

	# http links to https
	adminOnly '/port', (info) ->
		info config.port

	stats = (sortColumn) ->
		(info) ->
			starOfMonth = new Date
			starOfMonth.setDate 1
			starOfMonth.setHours 0
			starOfMonth.setMinutes 0
			starOfMonth.setSeconds 0
			last30Days = (new Date).subDays 30
			parallel
				count: User.count.bind User
				counters: Counter.find.bind Counter, email: $in: ['unsubscribe', 'resubscribe']
				last30DaysUsers: User.count.bind User, lastActivity: $gt: last30Days
				currentMonthUsers: User.count.bind User, lastActivity: $gt: starOfMonth
				friends: Friend.find.bind Friend
			, (results) ->
				friendsCount = 0
				friendsErrorsCount = 0
				friendsList = {}
				for f in results.friends || []
					k = if f.askedFrom > f.askedTo
						f.askedFrom + '-' + f.askedTo
					else
						f.askedTo + '-' + f.askedFrom
					if friendsList[k]
						friendsErrorsCount++
					else
						friendsList[k] = true
						if f.status is 'accepted'
							friendsCount++
				friendsErrorsCount = if friendsErrorsCount
					'\np(style="color: red;"): b\n\t| Doublons dans les demandes d\'amis : ' + friendsErrorsCount
				else
					''
				counter = (name) ->
					results.counters.findOne name: name
				exactAge = $divide: [$subtract: [new Date, "$birthDate"], 31558464000]
				match = $match:
					birthDate: $exists: true
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
						unsub = counter 'unsubscribe'
						unsub = if unsub then unsub.count else 0
						resub = counter 'resubscribe'
						resub = if resub then resub.count else 0
						# ages = ages.filter (age) ->
						# 	age._id < 150 and age.count > count / 300
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
						info jd 'p\n\t| ' + nbUsers + ' : ' + results.count +
							'\np\n\t| Nombre d\'utilisateurs actifs (depuis le ' + starOfMonth.toString('D/M/YYYY') + ') : ' + results.currentMonthUsers +
							'\np\n\t| Nombre d\'utilisateurs actifs (depuis le ' + last30Days.toString('D/M/YYYY') + ') : ' + results.last30DaysUsers +
							'\np\n\t| Amitiés : ' + friendsCount + friendsErrorsCount +
							'\np\n\t| Désinscriptions : ' + unsub +
							'\np\n\t| Résinscriptions : ' + resub +
							'\np\n\t| Âge moyen : ' + (age.replace '.', ',') +
							'\ntable' +
							'\n\ttr' +
							'\n\t\tth: a(href="/admin/stats/ages")!="Âge &nbsp; &nbsp;"' +
							'\n\t\tth: a(href="/admin/stats") ' + nbUsers +
							table
			, (err, key) ->
				info 'Error in ' + key + ': ' + err

	adminOnly '/stats', stats count: -1

	adminOnly '/stats/ages', stats _id: 1

	adminOnly '/stats/medias', (info) ->
		parallel
			status: Status.count.bind Status
			albums: Album.count.bind Album
			photos: Photo.count.bind Photo
			liens: Link.count.bind Link
			'vidéos': Video.count.bind Video
			'mesages de chat': Message.count.bind Message
			notifications: Notice.count.bind Notice
			'événements': Event.count.bind Event
			invitations: Invitation.count.bind Invitation
			'mentions W': PlusW.count.bind PlusW
			applications: App.count.bind App
		, (results) ->
			r = ''
			for key, count of results
				r += jd 'p ' + count + ' ' + key
			info r
		, (err) ->
			info err

	godOnly '/retina', (info) ->
		Photo.find()
		.limit 100

	usersTreated = []
	godOnly '/album/profile', (info) ->
		User.find
			photoAlbumId: null
			_id: $nin: usersTreated
		.limit 100
		.exec (err, users) ->
			if err
				info err
			else if users.length
				treatments = {}
				each users, ->
					usersTreated.push @id
					treatments[@id] = (done) =>
						Album.find
							user: @_id
							name: photoDefaultName()
						, (err, albumList) =>
							if err
								done err
							else
								if albumList.length > 0
									# In case of many "Photos de profil" albums
									if albumList.length > 1
										if @photoId
											Photo.findOne
												_id: @photoId
											, (err, photo) =>
												if err
													done err
												else
													albumId = photo.album
									else
										albumId = albumList[0]._id
										albumList[0].refreshPreview (err) ->
											if err
												warn err

									@photoAlbumId = albumId
									@save()

									lastFour = []
									limit = if albumId
										lastFour.push albumId
										3
									else
										4

									Album.find
										user: @_id
										name: $ne: photoDefaultName()
									.sort(lastAdd:'desc')
									.exec (err, albums) =>
										if err
											warn err
										else
											albumIds = albums.map (obj) ->
												obj._id
											Photo.aggregate [
												$match:
													status: "published"
													album: $in: albumIds
											,
												$group:
													_id: "$album"
													count: $sum: 1
											], (err, allData) =>
												if err
													warn err
												else
													tabData = {}
													for data in allData
														tabData[data._id] = data.count
													for album in albums
														if tabData[album._id] > 0
															lastFour.push album._id
															album.refreshPreview (err) ->
																if err
																	warn err
													lastFour = lastFour.slice 0, 4
													UserAlbums.findOne
														user: @_id
													, (err, userAlbum) =>
														if !userAlbum or err
															UserAlbums.create
																user: @_id
																lastFour: lastFour
															, (err, newUserAlbum) =>
																if err
																	warn err
																else
																	done()
														else
															userAlbum.update
																lastFour: lastFour
															, (err, newUserAlbum) =>
																if err
																	warn err
																else
																	done()

								else
									done()
				parallel treatments, ->
					info users.length + " utilisateurs mis à jour"
				, info
			else
				info "Boulot terminé"

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
