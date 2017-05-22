'use strict'

module.exports = (defer, start) ->

    # Make functions and config usables in views
    extend app.locals, functions
    extend app.locals,
        config: config
        options: options

    if https = config.wornet.protocole is 'https'
        app.set 'trust proxy', 1

    # Use redis for sessions
    redisStore = new RedisStore
    global.redis = redisStore.client

    redisOnly = require 'redis'
    global.redisClientEmitter = redisOnly.createClient process.env.REDIS_URL
    global.redisClientReciever = redisOnly.createClient process.env.REDIS_URL

    redisClientReciever.subscribe config.wornet.redis.defaultChannel

    RedisListener()

    session = require 'express-session'

    app.use session
        # Express session options
        resave: false,
        saveUninitialized: false,
        secret: process.env.SESSION_SECRET or "6qed36sQyAurbQCLNE3X6r6bbtSuDEcU"
        key: "w"
        store: redisStore
        proxy: https
        cookie: secure: https

    if config.env.development
        app.use (req, res, next) ->
            unless /\.coffee$/.test req.url
                next()
                return
            fs.readFile __dirname + '/../../../public/' + req.url, (err, content) ->
                if err
                    next()
                    return
                res.send content
    do start

    require(coreDir + 'global/request/handle-static') app

    app.on 'start', ->

        console['log'] 'Wornet is ready  ' + (new Date).log()

        defer.forEach (done) ->
            done app

        defer.done = true

        glob coreDir + 'global/start/**/*.coffee', (er, files) ->
            files.forEach (file) ->
                require file

    httpsPort = process.env.HTTPS_PORT or 443
    httpPort = process.env.HTTP_PORT or 80

    listen = (port) ->
        unless port is httpsPort
            global.server = app.listen port, (err) ->
                if err
                    throw err
                else
                    console['log'] '[%s] Listening on http://localhost:%d', app.settings.env, port
        else
            ca = if process.env.SSL_CA_CHAIN
                fs.readFileSync process.env.SSL_CA_CHAIN, 'utf8'
            else if process.env.SSL_CA_DIRECTORY
                glob process.env.SSL_CA_DIRECTORY, (er, files) ->
                    files.map file ->
                        fs.readFileSync file, 'utf8'
            else
                ['root.crt', 'intermediate.crt'].map (file) ->
                    fs.readFileSync '/etc/ssl/' + file, 'utf8'

            options =
                key: fs.readFileSync process.env.SSL_PRIVATE_KEY or '/etc/ssl/private/key.pem', 'utf8'
                ca: ca
                cert: fs.readFileSync process.env.SSL_CERTIFICATE or '/etc/ssl/certificate.crt', 'utf8'

            global.server = httpsServer.createServer(options, app).listen port, (err) ->
                if err
                    throw err
                else
                    console['log'] '[%s] Listening on https://localhost:%d', app.settings.env, port

    require('momentum-js').connect(app, 'mongodb://localhost:27017/game').then (momentum) ->
        momentum.setAuthorizationStrategy (mode, method, args, req) ->
            pieces = args[0].split '_'
            id = ((req.session or {}).user or {}).hashedId
            if pieces.length is 3 and pieces[0] in ['chessGames', 'chessMoves'] and id in pieces
                if pieces[0] is 'chessGames'
                    return mode is 'data'

                if method is 'remove'
                    return new Promise (resolve) ->
                        game =
                            date: new Date()
                            abandon: id
                        collection = 'chessGames_' + pieces.slice(1).join '_'
                        momentum.insert(collection, game).then ->
                            resolve true
                            return
                        return
                return method in ['find', 'insertOne', 'remove']

            return false

        # Handle errors and print in the console
        if config.port is httpsPort
            global.httpsServer = require 'https'
            app.all '*', (req, res, next) ->
                if req.secure
                    next()
                else
                    res.redirect 'https://' + req.hostname + req.url

            listen httpPort
            listen httpsPort
        else
            listen config.port
