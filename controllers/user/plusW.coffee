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
