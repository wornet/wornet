'use strict'

if config.wornet.events.enabled

	module.exports = (router) ->

		pm = new PagesManager router, 'move'

		pm.page '/event', (req) ->
			user: req.user

		pm.page '/search', (req) ->
			user: req.user

		router.get '/event/:id', (req, res) ->

			res.json
				event:
					coverImg: '/img/photo/200x55b61b6c7c5417381d678271.jpg'
					title: 'Parkour à Poitiers'
					recentStatus: [
						content: 'Bla bla'
					]
					medias: [
						type: 'image'
						src: '/img/photo/200x55b61b6c7c5417381d678271.jpg'
					]
					participants: [
						name:
							first: 'Toto'
							last: ''
							full: 'Toto'
					]
					organizers: [
						name:
							first: 'Tata'
							last: ''
							full: 'Tata'
					]
