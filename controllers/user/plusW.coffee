'use strict'

nbLikeChangeResponse = (err, newNbLike) ->
	if err
		@serverError err
	else
		@json newNbLike: newNbLike

module.exports = (router) ->

	router.put '', (req, res) ->
		if !req.user
			res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
		PlusWPackage.put req, res, nbLikeChangeResponse.bind res


	router.delete '', (req, res) ->
		if !req.user
			res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
		PlusWPackage.delete req, res, nbLikeChangeResponse.bind res

	router.post '/list', (req, res) ->
		PlusWPackage.get req, res, req.data.status, (err, likers) ->
			if err
				res.serverError err
			else
				res.json likers: likers
