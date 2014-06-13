'use strict'

# Dependancies to load
kraken = require 'kraken-js'
extend = require 'extend'
stitch  = require 'stitch'
glob = require 'glob'
express = require 'express'
path = require 'path'
connect = require 'connect'

app = express()

# Config load
autoloadDirectories = [
    'models',
    'core/utils'
]
options =
    onconfig: (config, next) ->
        # any config setup/overrides here
        next null, config

port = process.env.PORT || 8000

# Get functions
functions = require './core/utils/functions'
# Make functions usable in controllers and other stuff
extend global, functions

# Launch Kraken
app.use kraken options

# Make functions usable in views
extend app.locals, functions

# JS Compile
#app.get('/application.js', stitch.createPackage(
#    paths: [path.normalize(__dirname + '/lib'), path.normalize(__dirname + '/node_modules/twitter-bootstrap/js')]
#).createServer())

# Load all files contained in autoloadDirectories
autoloadDirectories.forEach (directory) ->
    glob directory + "/**/*.js", (er, files) ->
        files.forEach (file) ->
            loadedValue = require './' + file
            if typeof(loadedValue.name) is 'undefined' || empty(loadedValue.name)
                name = file.substr(directory.length + 1).replace(/\.[^\.]+$/g, '')
            else
                name = loadedValue.name
            global[name] = loadedValue unless global[name]?


app.listen port, (err) ->
    console.log '[%s] Listening on http://localhost:%d', app.settings.env, port
