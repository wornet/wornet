'use strict'

module.exports = (router) ->

	new Crud router
		.all (req, res, method) ->
			model = {}
			switch method

				when "GET"
					# List all events owned by the logged user
					Event
						.find
							user: req.user._id
						.sort
							registerDate: -1
						.exec (err, events) ->
							if err
								model.err = err
							else
								model.events = events
							model.datas = 
								events: events
								dateTexts: require(__dirname + '/../core/utils/dateTexts')()
							res.render 'agenda', model

				when "PUT"
					# Create new event on the logged user agenda
					eventData = req.body.event
					event = new Event
						user: req.user._id
						start: eventData.start
						end: eventData.end
					unless empty(eventData.title)
						event.title = eventData.title
					event.save (err) ->
						if err
							res.serverError err
						else
							res.json event: event

				when "POST"
					# Modify event (changes of dates, hours or name)
					eventData = req.body.event 
					Event.findById eventData.id, (err, event) ->
						if err
							res.serverError err
						else if event is null
							res.serverError s("L'événement est introuvable.")
						else if event.user + '' isnt req.user._id + ''
							res.serverError s("Vous n'êtes pas propriétaire de cet événement.")
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
									res.serverError err
								else
									res.json event: event

				when "DELETE"
					# Remove an event
					eventData = req.body.event
					Event.remove
						_id: eventData.id
						user: req.user._id
					, (err) ->
						if err
							res.serverError err
						else
							res.json()
