'use strict'

module.exports = (router) ->

	router.get '/', (req, res) ->

		model = {}
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
						model.events = events
					date = new Date()
					d = date.getDate()
					m = date.getMonth()
					y = date.getFullYear()
					model.datas = 
						events: [
							{
								title: "All Day Event"
								start: new Date(y, m, 1)
							}
							{
								title: "Long Event"
								start: new Date(y, m, d - 5)
								end: new Date(y, m, d - 2)
							}
							{
								id: 999
								title: "Repeating Event"
								start: new Date(y, m, d - 3, 16, 0)
								allDay: false
							}
							{
								id: 999
								title: "Repeating Event"
								start: new Date(y, m, d + 4, 16, 0)
								allDay: false
							}
							{
								title: "Birthday Party"
								start: new Date(y, m, d + 1, 19, 0)
								end: new Date(y, m, d + 1, 22, 30)
								allDay: false
							}
							{
								title: "Click for Google"
								start: new Date(y, m, 28)
								end: new Date(y, m, 29)
								url: "http://google.com/"
							}
						]
						dateTexts: require(__dirname + '/../core/utils/dateTexts')()
					res.render 'agenda', model
		)

	router.get '/calendar/feeds', (req, res) ->

		http = require 'http'

		model = {}
		http.get
			host: 'www.google.com'
			port: 80
			path: '/calendar/feeds/' + (if lang() is 'fr' then 'fr_fr' else 'usa__en') + '%40holiday.calendar.google.com/public/basic?start=' + req.body.start + '&end=' + req.body.end
		, (resp) ->
			response = ''
			resp.on 'data', (chunk) ->
				response += chunk
			resp.on 'end', () ->
				res.end response
		.on "error", (e) ->
			model.err = e.message
			res.render 'agenda', model