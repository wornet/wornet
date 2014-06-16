'use strict'

standartTimeout = 12000

onready = require './test'

describe "/", ->

	@timeout standartTimeout

	app = undefined
	agent = undefined

	beforeEach (done) ->
		onready (givenApp, givenAgent) ->
			app = givenApp
			agent = givenAgent
			done()


	it "should contain 'Wornet'", (done) ->
		agent.get("/").expect(200).expect("Content-Type", /html/).expect(/Wornet/).end (err, res) ->
			done err
