"use strict"
#global describe:false, it:false, beforeEach:false, afterEach:false

kraken = require("kraken-js")
express = require("express")
request = require("supertest")
describe "/", ->
    app = undefined
    mock = undefined
    beforeEach (done) ->
        app = express()
        app.on "start", done
        app.use kraken(basedir: process.cwd())
        mock = app.listen(1337)

    afterEach (done) ->
        mock.close done

    it "should say \"hello\"", (done) ->
        setTimeout (->
            console.log "la"
            request(mock).get("/").expect(200).expect("Content-Type", /html/).expect(/Hello, /).end (err, res) ->
                done err
        ), 4000
        console.log "ici"

