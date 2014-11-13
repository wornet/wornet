'use strict'

module.exports = (router) ->

	router.get '/recent/:id', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, req.params.id

	router.get '/recent', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res

	router.put '/add/:id', (req, res) ->
		StatusPackage.add req, (err, status) ->
			if err
				res.serverError err
			else
				StatusPackage.getRecentStatusForRequest req, res, req.params.id, newStatus: status

	router.put '/add', (req, res) ->
		StatusPackage.add req, (err, status) ->
			if err
				res.serverError err
			else
				StatusPackage.getRecentStatusForRequest req, res, null, newStatus: status
