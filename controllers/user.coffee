'use strict'

model = {}

module.exports = (router) ->

	router.get '/login', (req, res) ->

		res.render 'login', model

	router.post '/login', (req, res) ->

		res.render 'login', model

	router.get '/logout', (req, res) ->

		res.render 'logout', model

	router.get '/signin', (req, res) ->

		res.render 'signin', model

	router.post '/signin', (req, res) ->

		res.render 'signin', model

	router.get '/forgotten-password', (req, res) ->

		res.render 'forgotten-password', model

	router.post '/forgotten-password', (req, res) ->

		res.render 'forgotten-password', model
