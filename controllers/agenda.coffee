'use strict'

module.exports = (router) ->

	router.get '/', (req, res) ->
		log "GET"
		model = {}
		User.find(
			'name.first': 'Kyle'
		, (err, kyle) ->
			if err
				model.err = err
				res.render 'agenda', model
			else
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
		)

	router.put '/', (req, res) ->
		log "PUT"
		model = {}
		User.find
			'name.first': 'Kyle'
		, (err, kyle) ->
			if err
				res.json
					err: err
			else
				eventData = req.body.event
				event = new Event
					user: kyle.id
					start: eventData.start
					end: eventData.end
				unless empty(eventData.title)
					event.title = eventData.title
				event.save (err) ->
					if err
						res.json
							err: err
					else
						res.json event

	router.delete '/', (req, res) ->
		log "DELETE"
		model = {}
		User.find
			'name.first': 'Kyle'
		, (err, kyle) ->
			if err
				res.json
					err: err
			else
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

	router.post '/', (req, res) ->
		log "POST"
		model = {}
		User.find
			'name.first': 'Kyle'
		, (err, kyle) ->
			if err
				res.json
					err: err
			else
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
