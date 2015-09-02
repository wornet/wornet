'use strict'

nbLikeChangeResponse = (err, newNbLike) ->
	if err
		@serverError err
	else
		@json newNbLike: newNbLike

module.exports = (router) ->

	router.put '', (req, res) ->
		PlusWPackage.put req, res, nbLikeChangeResponse.bind res


	router.delete '', (req, res) ->
		PlusWPackage.delete req, res, nbLikeChangeResponse.bind res

	router.post '/list', (req, res) ->
		PlusWPackage.get req, res, req.data.status, (err, likkers) ->
			if err
				res.serverError err
			else
				res.json likkers: likkers
