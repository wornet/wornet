#!/usr/bin/env coffee

'use strict'

if process.env.NEWRELIC_ENABLED
    require 'newrelic'

require './core/server/init'
require './core/global/start/bootstrap'

defer = []
app.onready = (done) ->
    if defer.done
        done app
    else
        defer.push done

# Load all files contained in autoloadDirectories
onready = require coreDir + 'system/autoload'
onready ->

    # When no more directory need to be loaded
    (require coreDir + 'global/start/app') defer, ->

        # Launch Kraken
        app.use kraken options

exports = module.exports = app
