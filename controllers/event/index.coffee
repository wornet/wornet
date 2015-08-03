'use strict'

module.exports = (router) ->

	pm = new PagesManager router, 'event'

	pm.page '', (req) ->
		user: req.user

	router.get '/:id', (req, res) ->

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
