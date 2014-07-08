'use strict'

module.exports = (router) ->

	(new Crud router).all (req, res, method) ->
		model = {}
		User.find
			'name.first': 'Kyle'
		, (err, kyle) ->
			if err
				model.err = err
				if method is "GET"
					res.render 'agenda', model
				else
					res.json model
			else
				switch method

					when "GET"
						Event.find(
							user: kyle.id
						).sort(
							registerDate: -1
						).exec (err, events) ->
							if err
								model.err = err
							else
								model.events = events
							model.datas = 
								events: events
								dateTexts: require(__dirname + '/../core/utils/dateTexts')()
							res.render 'agenda', model

					when "PUT"
						eventData = req.body.event
						event = new Event
							user: kyle.id
							start: eventData.start
							end: eventData.end
						unless empty(eventData.title)
							event.title = eventData.title
						event.save (err) ->
							if err
								res.json err: err
							else
								res.json event

					when "POST"
						eventData = req.body.event 
						Event.findById eventData.id, (err, event) ->
							if err
								res.json
									err: err
							else if event is null
								res.json
									err: s("L'événement [" + eventData.id + "] est introuvable.")
							else if event.user isnt kyle.id
								res.json
									err: s("Vous n'êtes pas propriétaire de cet événement.")
							else
								for key, value of eventData
									if key isnt 'id'
										if key in ['start', 'end']
											eventData[key] = new Date eventData[key]
										event[key] = eventData[key]
								if typeof(event.allDay) is 'string'
									event.allDay = event.allDay is 'true'
								event.save (err) ->
									if err
										res.json
											err: err
									else
										res.json event

					when "DELETE"
						eventData = req.body.event
						Event.remove
							_id: eventData.id
							user: kyle.id
						, (err) ->
							if err
								res.json
									err: err
							else
								res.json {}
