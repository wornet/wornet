'use strict'

do ->

    global.coreDir = __dirname + '/../../'
    global.rootDir = coreDir + '../'
    require coreDir + 'system/date'
    console['log'] 'Starting Wornet  ' + (new Date).log()

    # Dependancies to load
    'kraken-js child_process extend glob express path connect fs mongoose crypto passport stylus imagemagick deep-extend ua-parser-js vicopo x-ray'
    .split(/\s+/).forEach (dependancy) ->
        try
            global[dependancy.replace(/([^a-zA-Z0-9_]|js$)/g, '')] = require dependancy
        catch e
            throw dependancy + ' cannot be loaded due to: ' + e

    # Get shortcuts from dependancies
    'child_process.exec mongoose.Schema'
    .split(/\s+/).forEach (shortcut) ->
        shortcut = shortcut.split '.'
        global[shortcut[1]] = global[shortcut[0]][shortcut[1]]


    global.app = express()

    session = require 'express-session'

    # Get functions
    extend global, require coreDir + 'utils/functions'
    extend global,
        # Store engines
        RedisStore: require('connect-redis') session

    # Config load
    global.config = require(coreDir + 'global/start/config') app.settings.env, process.env.PORT
    port = config.port

    # Set application options
    global.options = require(coreDir + 'system/options') app, port

    unless global.stopCatchException

        errorHandler = (err) ->
            if err.code is 'EADDRINUSE'
                console['log'] 'Attempt to listen ' + port + ' on ' + app.settings.env + '(' + app.get('env') + ')'
                throw err
            prefix = 'Caught exception: '
            if err.message
                err.message = prefix + err.message
            else
                err = prefix + err
            warn err, false
            if global.GitlabPackage
                GitlabPackage.issue err

            if !config.env.development
                if global.server
                    global.server.close()
                delay 1.seconds, ->
                    process.exit 1

        process.on 'uncaughtException', errorHandler
        process.on 'unhandledRejection', errorHandler
