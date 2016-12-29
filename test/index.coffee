'use strict'

onready = require './test'

describe "/", ->

    @timeout 12.seconds

    app = undefined
    agent = undefined

    beforeEach (done) ->
        onready.app (givenApp, givenAgent) ->
            app = givenApp
            agent = givenAgent
            done()


    # it "should contain 'Wornet'", (done) ->
    #     agent.get("/").expect(200).expect("Content-Type", /html/).expect(/Wornet/).end (err, res) ->
    #         done err
