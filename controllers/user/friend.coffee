'use strict'

module.exports = (router) ->

	# Without AJAX
	router.get '/:id/:name', (req, res) ->
		# When user ask some other user for friend
		id = req.params.id
		UserPackage.askForFriend id, req, (data) ->
			if empty data.err
				req.flash 'friendAsked', s("Demande envoyée à " + escape(req.params.name))
			else
				req.flash 'profileError', s("Erreur : " + data.err)
			res.redirect '/user/profile/' + encodeURIComponent(id) + '/' + encodeURIComponent(req.params.name)

	# With AJAX
	router.post '/', (req, res) ->
		# When user ask some other user for friend
		UserPackage.askForFriend req.body.userId, req, (data) ->
			res.json data

	router.post '/accept', (req, res) ->
		# When user accept friend ask
		UserPackage.setFriendStatus req, 'accepted', (data) ->
			res.json data

	router.post '/ignore', (req, res) ->
		# When user ignore friend ask
		UserPackage.setFriendStatus req, 'refused', (data) ->
			res.json data