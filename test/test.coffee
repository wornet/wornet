'use strict'

# No conflict if a 8000 port app is running
process.env.PORT = 8001
rootRequire = (file) ->
    require __dirname + '/../' + file
rootRequire 'core/global/start/bootstrap'

fs.exists 'mongod.lnk', (exists) ->
    if exists
        (require __dirname + '/../core/system/command.js') 'mongod.lnk'

request = require 'supertest'
chai = require 'chai'
chai.should()

extend global,
    assert: require 'assert'
    chai: chai
    expect: chai.expect

module.exports =
    utils: (done) ->
        autoload = rootRequire 'core/system/autoload'
        autoload ->
            done()

    app: (done) ->
        global.stopCatchException = true
        app = rootRequire 'index'
        agent = request.agent app
        app.onready ->
            done app, agent
