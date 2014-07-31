'use strict'

module.exports = (router) ->


	(new PagesManager(router))
		.page('/newsroom')
		.page('/jobs')
		.page('/legals')


	alias =
		'': 'user/profile'
		login: 'user/login'
		signin: 'user/signin'
		logout: 'user/logout'
		'forgotten-password': 'user/forgotten-password'
		profile: 'user/profile'

	for as, route of alias
		((as, route) ->
			router.get '/' + as, (req, res) ->
				res.redirect '/' + route
		)(as, route)
