'use strict'

module.exports = (router) ->

	# With AJAX
	router.post '/', (req, res) ->
		# When user ask some other user for friend
		UserPackage.askForFriend req.body.userId, req, (data) ->
			res.json data

	router.post '/accept', (req, res) ->
		# When user accept friend ask
		UserPackage.setFriendStatus req, req.body.id, 'accepted', (data) ->
			res.json data

	router.get '/accept/:friendAskId', (req, res) ->
		# When user accept friend ask
		UserPackage.setFriendStatus req, req.params.friendAskId, 'accepted', ->
			res.redirect req.data.goingTo

	router.get '/best/:friendHashedId', (req, res) ->
		# When a user subscribe to all the posts of a friend
		req.user.saveAsABestFriend req.params.friendHashedId, (err) ->
			if err
				res.serverError err
			else
				res.json success: true

	router.get '/normal/:friendHashedId', (req, res) ->
		# When a user subscribe to all the posts of a friend
		req.user.saveAsANormalFriend req.params.friendHashedId, (err) ->
			if err
				res.serverError err
			else
				res.json success: true

	router.post '/ignore', (req, res) ->
		# When user ignore friend ask
		UserPackage.setFriendStatus req, req.body.id, 'refused', (data) ->
			res.json data

	router.delete '/', (req, res) ->
		# When user ignore friend ask
		him = cesarRight req.body.id
		me = req.user.id
		UserPackage.cacheFriends me, him, false
		Friend.remove
			$or: [
				askedFrom: me
				askedTo: him
			,
				askedFrom: him
				askedTo: me
			]
			status: 'accepted'
		, (err, count) ->
			if err
				res.serverError err
			else
				res.json count: count
				if count
					req.user.friends = req.user.friends.filter (user) ->
						! equals user.id, him
					req.user.numberOfFriends = req.user.friends.length
					req.session.user.friends = req.user.friends
					req.session.friends = req.user.friends
					req.session.user.numberOfFriends = req.session.user.friends.length

					Notice.find
						type: 'friendAccepted'
						$or: [
							launcher: me
							place: him
						,
							launcher: him
							place: me
						,
							launcher: him
							place: him
						,
							launcher: me
							place: me
						]
					, (err, notices) ->
						for notice in notices
							if notice.createdAt > (new Date).subHours config.wornet.friends.hoursBeforeRemoveNotification
								notice.remove()
						if err
							res.serverError err

	# Without AJAX
	router.get '/:id/:name', (req, res) ->
		# When user ask some other user for friend
		id = req.params.id
		UserPackage.askForFriend id, req, (data) ->
			if empty data.err
				req.flash 'friendAsked', s("Demande envoyée à " + escape(req.params.name))
			else
				req.flash 'profileErrors', s("Erreur : " + data.err)
			res.redirect '/user/profile/' + encodeURIComponent(id) + '/' + encodeURIComponent(req.params.name)
