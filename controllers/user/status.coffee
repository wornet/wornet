'use strict'

module.exports = (router) ->

	router.get '/recent', (req, res) ->
		StatusPackage.getRecentStatus req, res

	router.put '/add', (req, res) ->
		StatusPackage.add req, (err, status) ->
			if err
				res.json err: err
			else
				StatusPackage.getRecentStatus req, res, newStatus: status
