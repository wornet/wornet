'use strict'

model = {}

module.exports = (router) ->

	router.get '/agenda', (req, res) ->

		User.find(
			'name.first': 'Kyle'
		, (err, kyle) ->
			if err
				model.err = err
				res.render 'agenda', model
			else
				Event.find(
					user: kyle
				).sort(
					registerDate: -1
				).exec (err, events) ->
					if err
						model.err = err
					else
						mdel.events = events
					res.render 'agenda', model
