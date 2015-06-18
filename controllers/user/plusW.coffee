'use strict'

module.exports = (router) ->

	router.put '', (req, res) ->
		PlusWPackage.put req, res, (err, newNbLike) ->
			if err
				res.serverError err
			else
				res.json newNbLike


	router.delete '', (req, res) ->
		PlusWPackage.delete req, res, (err, newNbLike) ->
			if err
				res.serverError err
			else
				res.json newNbLike
