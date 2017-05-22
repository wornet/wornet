'use strict'

useCdn = false
csrfDetect = (err) ->
    (err + '').replace(/^Error:\s/, '') is "CSRF token mismatch"
csrfReplace = ->
    s("La session a expiré")

flash = require('connect-flash')
cookieParser = require(config.middleware.cookieParser.module.name)

module.exports = (app, port) ->

    trackers = null

    cookiesInit = ->
        cookieParserArguments = config.middleware.cookieParser.module.arguments
        if process.env.COOKIE_PARSER_SECRET
            cookieParserArguments[0] = process.env.COOKIE_PARSER_SECRET
        cookieParser.apply app, cookieParserArguments

    # Trace the error in log when user(s) are not found
    someUsersNotFound = (req) ->
        err = new PublicError s("Impossible de trouver tous les utilisateurs")
        warn err, req
        err

    app.on 'middleware:after:session', () ->

        # Flash session (store data in sessions to the next page only)
        app.use flash()
        # Allow to set and get cookies in routes methods
        app.use cookiesInit()

        # Check if user is authenticated and is allowed to access the requested URL
        app.use auth.isAuthenticated

    trackers: ->
        unless trackers
            trackers = {}
            piwik = config.wornet.trackers.piwik
            env = config.wornet.env || app.settings.env || 'dev'
            if piwik.enabled
                trackers.piwik = piwik[env] || piwik.dev
            ga = config.wornet.trackers.googleAnalytics
            if ga.enabled
                trackers.googleAnalytics = ga[env] || ga.dev
        trackers

    mainCss: ->
        if useCdn
            # CDN resources
            [
                "//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"
                "//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css"
                "//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/themes/smoothness/jquery-ui.css"
                "//cdnjs.cloudflare.com/ajax/libs/fullcalendar/2.0.2/fullcalendar.css"
                "//cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/css/toastr.min.css"
                style("app")
                ['ios-app', style('ios-app')]
            ]
        else
            # locales resources
            [
                "/components/bootstrap/css/bootstrap.min.css"
                "/components/bootstrap/css/bootstrap-theme.min.css"
                "/components/bootstrap/css/glyphicons.css"
                "/components/bootstrap/css/glyphicons-filetypes.css"
                "/components/bootstrap/css/glyphicons-halflings.css"
                "/components/bootstrap/css/glyphicons-social.css"
                "/components/jquery/css/jquery-ui.css"
                "/components/jquery/css/fullcalendar.css"
                "/components/toastr/css/toastr.min.css"
                "/components/tag-it/css/jquery.tagit.css"
                style("app")
                ['ios-app', style('ios-app')]
            ]

    env: (key) ->
        process.env[key] or null

    css: ->
        if config.env.development
            main: @mainCss()
        else
            main: [style("all")]

    mainJs: ->
        js = if useCdn
            # CDN resources
            [
                ['if lt IE 9', "//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"]
                ['if gte IE 9', "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"]
                ['non-ie', "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"]
                #"//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js"
                "//angular-ui.github.io/ui-calendar/bower_components/jquery-ui/ui/jquery-ui.js"
                "//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"
                "//cdnjs.cloudflare.com/ajax/libs/fastclick/1.0.3/fastclick.min.js"
                "//cdnjs.cloudflare.com/ajax/libs/bootbox.js/4.3.0/bootbox.min.js"
                #"//ajax.googleapis.com/ajax/libs/angularjs/1.3.2/angular.min.js"
                "//ajax.googleapis.com/ajax/libs/angularjs/1.3.2/angular-animate.min.js"
                "//ajax.googleapis.com/ajax/libs/angularjs/1.3.2/angular-sanitize.min.js"
                "//cdnjs.cloudflare.com/ajax/libs/angular-i18n/1.2.15/angular-locale_fr-fr.js"
                #"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular-route.js"
                #"//angular-ui.github.io/ui-calendar/bower_components/angular/angular.js"
                "//angular-ui.github.io/bootstrap/ui-bootstrap-tpls-0.9.0.js"
                "//rawgit.com/angular-ui/ui-calendar/master/src/calendar.js"
                "//rawgit.com/angular-ui/ui-calendar/master/src/calendar.js"
                "//cdnjs.cloudflare.com/ajax/libs/moment.js/2.7.0/moment-with-langs.min.js"
                #"//cdnjs.cloudflare.com/ajax/libs/moment.js/2.7.0/moment.min.js"
                "//cdnjs.cloudflare.com/ajax/libs/fullcalendar/2.0.2/fullcalendar.min.js"
                #"//cdnjs.cloudflare.com/ajax/libs/fullcalendar/2.0.2/lang/fr.js"
                #"//arshaw.com/js/fullcalendar-1.5.3/fullcalendar/gcal.js"
                "/components/angular/js/calendar-fr.js"
                "//rawgit.com/angular-ui/ui-calendar/master/src/calendar.js"
                "//cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/js/toastr.min.js"
                "//connect.facebook.net/fr_FR/sdk.js"
                script("app")
            ]
        else
            # locales resources
            [
                ['if lt IE 9', "/components/css3-mediaqueries/js/css3-mediaqueries.js"]
                ['if lt IE 9', "/components/jquery/js/jquery-1.js"]
                ['if gte IE 9', "/components/jquery/js/jquery-2.js"]
                ['non-ie', "/components/jquery/js/jquery-2.js"]
                "/components/jquery/js/jquery-ui.min.js"
                "/components/bootstrap/js/bootstrap.min.js"
                #"/components/angular/js/angular.js"
                "/components/angular/js/angular-animate.js"
                "/components/angular/js/angular-locale_fr-fr.js"
                "/components/angular/js/angular-sanitize.js"
                #"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular-route.js"
                "/components/bootstrap/js/ui-bootstrap-tpls.min.js"
                "/components/bootstrap/js/bootbox.min.js"
                "/components/fastclick/js/fastclick.min.js"
                "/components/moment/js/moment-with-langs.min.js"
                script("app")
                "/components/jquery/js/fullcalendar.min.js"
                #"/components/jquery/js/fullcalendar-gcal.js"
                "/components/angular/js/calendar-fr.min.js"
                "/components/angular/js/calendar.min.js"
                "/components/toastr/js/toastr.min.js"
                "/components/facebook/js/sdk.js"
                "/components/tag-it/js/tag-it.min.js"
            ]
        if options.trackers().piwik
            js.push "/components/piwik/js/piwik.js"
        if options.trackers().googleAnalytics
            js.push "/components/google/js/analytics.js"
        js

    js: ->
        if config.env.development
            main: @mainJs()
        else
            main: [script("all")]

    onconfig: (localConfig, next) ->
        # middleware = localConfig.get 'middleware'
        # token = require 'lusca/lib/token'
        # middleware.appsec.module.arguments[0].csrf = impl:
        #     create: token.create
        #     validate: (req, str) ->
        #         if req.url is '/user/photo' and req.method is 'POST'
        #             true
        #         else
        #             token.validate req, str
        # Available shorthand methods to all request objects in controllers
        extend app.request,
            # get objets of the different alert types for a given key
            getAlerts: (key) ->
                errors = @flash key + 'Errors'
                unless empty errors
                    errors.map GitlabPackage.error
                danger: errors
                success: @flash key + 'Success'
                info: @flash key + 'Infos'
                warning: @flash key + 'Warnings'
            # get id from hashed or the id of the user logged in if it's null
            getRequestedUserId: (id) ->
                if id is null and @user
                    @user.id
                else
                    cesarRight id
            # get request header or empty string if it's not contained
            getHeader: (name) ->
                @headers[name.toLowerCase()] || ''
            # Ask for redirect at next request
            goingTo: (url = null) ->
                if url is null
                    if @session.goingTo?
                        url = @session.goingTo
                        delete @session.goingTo
                else if url isnt '/user/notify'
                    @session.goingTo = url
                url
            # Get a cookie value from name or null if it does not exists
            cookie: (name) ->
                if @cookies[name]?
                    @cookies[name]
                else if @signedCookies[name]?
                    @signedCookies[name]
                else
                    null
            # Get from cache if present in user session, else calculate
            cache: (key, calculate, done) ->
                if typeof(key) is 'function'
                    done = calculate
                    calculate = key
                    key = codeId()
                unless @session.cache?
                    @session.cache = {}
                cache = @session.cache
                if typeof cache[key] is 'undefined'
                    calculate (err, value) ->
                        unless err
                            cache[key] = value
                        done err, value, false
                else
                    done null, cache[key], true
            # Empty the user session cache
            cacheFlush: (key = null) ->
                if key is null
                    @session.cache = {}
                else
                    if key is 'friends'
                        delete @user.friends
                        delete @user.friendAsks
                        delete @session.user.friends
                        delete @session.user.friendAsks
                        delete @session.friends
                        delete @session.friendAsks
                    if @session.cache
                        delete @session.cache[key]
            # get friends of the user logged in
            getFriends: (done, forceReload = false) ->
                if ! forceReload and @session.friends and @session.friendAsks
                    done null, @session.friends, @session.friendAsks
                else if @user
                    @user.getFriends done, forceReload
                else
                    done null, [], []
            # get friends of the user logged in
            getFriendsFromDataBase: (done) ->
                @getFriends done, true
            getLoggedFriends: ->
                if @session.friends
                    @session.friends
                        .map (friend) ->
                            userId = strval friend._id || friend.id
                            friend = objectToUser(friend).publicInformations()
                            if NoticePackage.isPresent userId
                                friend.present = true
                            friend
                        .findMany present: true
                else
                    []
            # add a friend to the current user
            addFriend: (user) ->
                req = @
                @session.reload (err) ->
                    if err
                        throw err
                    req.cacheFlush 'friends'
                    req.user.friends.push user
                    req.user.numberOfFriends = req.user.friends.length
                    req.session.user.friends = req.user.friends
                    req.session.friends = req.user.friends
                    req.session.user.numberOfFriends = req.session.user.friends.length
                    req.session.save (err) ->
                        if err
                            throw err
            # delete a notification
            deleteNotification: (id, done) ->
                if @session.notifications
                    notifications = []
                    for notification in @session.notifications
                        unless notification[0] is id
                            notifications.push notification
                    @session.notifications = notifications
                    Notice.remove
                        id: id
                        user: @user.id
                    , (err) ->
                        if err
                            console.warn err
                        done err, notifications
                else
                    done new PublicError s("Aucune notification")
            # get users from friend, me
            getKnownUsersByIds: (ids, done) ->
                @getUsersByIds ids, done, false
            # get users from friends, me, or from database
            getUsersByIds: (ids, done, searchInDataBase = true) ->
                currentUser = @user
                ids = ids.map strval
                if ids.contains 'undefined'
                    throw new Error 'ids must not contain undefined'
                idsToFind = []
                usersMap = {}
                req = @
                @getFriends (err, friends, friendAsks) ->
                    if err
                        done err, null, false
                    else
                        ids.each ->
                            user = (if currentUser and @ is currentUser.id
                                currentUser
                            else if friends
                                friends.findOne id: @
                            )
                            if user
                                usersMap[@] = objectToUser user
                            else
                                idsToFind.push @
                        idsToFind = idsToFind.unique()
                        if idsToFind.length > 0
                            if searchInDataBase
                                User.find _id: $in: idsToFind, (err, otherUsers) ->
                                    if err
                                        done err, null, true
                                    else
                                        err = (if otherUsers.length is idsToFind.length
                                            null
                                        else
                                            someUsersNotFound req
                                        )
                                        otherUsers.each ->
                                            usersMap[@id] = @
                                        done err, usersMap, true
                            else
                                done someUsersNotFound(req), null, false
                        else
                            done null, usersMap, false
            # get user from friends, me, or from database
            getUserById: (id, done, searchInDataBase = true) ->
                req = @
                @getUsersByIds [id], (err, usersMap) ->
                    if err or ! usersMap or ! usersMap[id]
                        done someUsersNotFound req
                    else
                        done null, usersMap[id]
            # get fresh notifications
            refreshNotifications: (next) ->
                if user = @user
                    sessionInfos = @session.columns ['notifications', 'friendAsks', 'friends']
                    userId = user._id
                    Notice.find {user: userId, type: $nin: ["chatMessage", "sms"]}
                        .sort _id: 'desc'
                        .limit config.wornet.limits.notifications
                        .exec (err, coreNotifications) =>
                            if err
                                warn err, @
                            coreNotificationsWithUsers = []
                            usersToSearch = []
                            statusToSearch = []
                            indexedStatus = []
                            parallelTab = {}

                            for notice in coreNotifications
                                if notice.place and notice.launcher and notice.user
                                    usersToSearch.push notice.launcher, notice.place, notice.user
                                    statusToSearch.push notice.attachedStatus

                            usersToSearch = usersToSearch.unique()
                            statusToSearch = statusToSearch.unique()

                            parallel
                                getUsers: (done) =>
                                    @getUsersByIds usersToSearch, (err, usersMap) ->
                                        if err || !usersMap
                                            done err
                                        else
                                            done null, usersMap
                                getStatus: (done) =>
                                    Status.find
                                        _id: $in: statusToSearch
                                    , (err, statusList) ->
                                        if err || !statusList
                                            done err
                                        else
                                            done null, statusList
                            , (UserStatusResults) ->
                                for status in UserStatusResults.getStatus
                                    indexedStatus[status._id] = status
                                for notice in coreNotifications
                                    isRead = notice.isRead
                                    notice = notice.toObject()
                                    notice.isRead = isRead
                                    notice.launcher = UserStatusResults.getUsers[notice.launcher]
                                    notice.place = UserStatusResults.getUsers[notice.place]
                                    notice.user = UserStatusResults.getUsers[notice.user]
                                    notice.attachedStatus = indexedStatus[notice.attachedStatus]
                                    if notice.launcher
                                        parallelTab[notice._id] = [notice.launcher.getFriends, notice.launcher]
                                    coreNotificationsWithUsers.push notice

                                parallel parallelTab
                                , (friendsResults) ->
                                    for newNotice in coreNotificationsWithUsers
                                        friendsHashedIds = []
                                        if newNotice.launcher
                                            for friend in friendsResults[newNotice._id]
                                                friendsHashedIds.push friend.hashedId
                                            newNotice.launcherFriends = friendsHashedIds

                                    next getNotifications sessionInfos.notifications || [], coreNotificationsWithUsers || [], sessionInfos.friendAsks, sessionInfos.friends, user
                                , ->
                                    next []

                            , ->
                                next []
                else
                    next []
            # test credentials with anti-brute-force protection
            tryPassword: (user, password, done) ->
                if 'function' is typeof user
                    done = user
                    password = @body.password
                    user = @user
                else if 'function' is typeof password
                    done = password
                    password = @body.password
                ip = @connection.remoteAddress
                res = @res
                AntiBruteForcePackage.test ip, user.id, (err) ->
                    if err
                        res.serverError err
                    else
                        user.passwordMatches password, done


        # Save original method(s) that we will override
        redirect = app.response.redirect
        setHeader = app.response.setHeader
        render = app.response.render
        end = app.response.end
        cookie = app.response.cookie
        json = app.response.json

        # Available shorthand methods to all response objects in controllers
        responseErrors =
            notFound: 404
            serverError: 500
            forbidden: 403
            unautorized: 401
        for key, val of responseErrors
            app.response[key] = do (key, val) ->
                (model = {}, noReport) ->
                    if val is 404
                        log 'not found'
                    if typeof(model) is 'string' or model instanceof Error or model instanceof PublicError
                        model = err: model
                    err = ((@locals || {}).err || model.err) || new Error "Unknown " + val + " " + key.replace(/Error$/g, '').replace(/([A-Z])/g, ' $&').toLowerCase() + " error"
                    console['log'] err
                    warn err, false, @req
                    unless noReport
                        GitlabPackage.error 'Error ' + val + '\n' + @req.url + '\n' + @req.getHeader('referrer') + '\n' + err
                        noReport = true
                    model.err = err
                    model.statusCode = val
                    @status val
                    if @isJSON
                        @json model, noReport
                    else
                        @render 'errors/' + val, model

        extend app.response,
            ###
            Complete a local URL if needed
            @param string URL

            @return string complete URL
            ###
            localUrl: (path) ->
                if config.wornet.parseProxyUrl and path.charAt(0) is '/'
                    for proxy in config.wornet.proxies
                        if (proxy.indexOf('https://') is 0 and !@secure) or (proxy.indexOf('http://') is 0 and @secure)
                            continue
                        proxy = proxy.replace(/https?:\/\//g, '').split /\//g
                        if proxy.length > 1 and proxy[0] is @hostname
                            return '/' + proxy.slice(1).join('/') + path
                path
            redirect: ->
                params = Array.prototype.slice.call arguments
                if typeof params[0] is 'string'
                    params[0] = @localUrl params[0]
                redirect.apply @, params
            safeHeader: (done) ->
                try
                    done()
                catch e
                    if equals e, "Error: Can't set headers after they are sent."
                        if config.env.development
                            if @endAt
                                warn @endAt, @req
                            throw e
                    else
                        if config.env.development
                            warn e, @req
                            @serverError e
            setHeader: ->
                res = @
                params = arguments
                @safeHeader ->
                    setHeader.apply res, params
            render: ->
                res = @
                params = arguments
                if params[1] and params[1].err and ! config.env.development
                    GitlabPackage.error params[1].err
                    if params[1].err instanceof PublicError
                        params[1].err = strval params[1].err
                    else if csrfDetect params[1].err
                        params[1].err = new PublicError csrfReplace()
                    else
                        delete params[1].err
                next = ->
                    res.safeHeader ->
                        render.apply res, params

                @locals.trackers = options.trackers()
                @locals.vars = if @req.user
                    @req.user.columns ['role', 'age', 'openedShutter', 'job', 'jobPlace', 'city', 'numberOfFriends']
                else
                    role: 'visitor'
                if @req and @req.session
                    @req.refreshNotifications (notifications) ->
                        res.locals.notifications = notifications
                        next()
                else
                    next()
            end: ->
                res = @
                params = arguments
                @safeHeader =>
                    try
                        end.apply res, params
                    catch e
                        if equals e, "Caught exception: write after end"
                            warn e.stack, req
                        else
                            throw e
                    finally
                        @endAt = new Error "End here:"
            publicJson: (data = {}, noReport) ->
                @json data, noReport, true
            json: (data = {}, noReport, _public) ->
                if typeof @ is 'undefined'
                    log "No context"
                if data.statusCode? and data.statusCode is 500
                    if data.err instanceof Error
                        if csrfDetect data.err
                            data.csrfBroken = true
                            data.err = new PublicError csrfReplace()
                        if config.env.development
                            data.stack = data.err.stack
                    data.err = strval(data.err || s("Erreur inconnue"))
                if data.err and ! noReport
                    GitlabPackage.error data.err
                unless _public
                    data._csrf ||= @locals._csrf
                json.call @, data
            setTimeLimit: (time = 0) ->
                if typeof(@excedeedTimeout) isnt 'undefined'
                    clearTimeout @excedeedTimeout
                if time > 0
                    res = @
                    unless /^\/api\/mm\//.test @req.url
                        @excedeedTimeout = delay time.seconds, ->
                            res.serverError standartError()
            catch: (callback) ->
                res = @
                ->
                    try
                        callback()
                    catch e
                        res.serverError e
            cookie: (name, value, options = {}) ->
                if config.wornet.protocole is 'https' and typeof options.secure is 'undefined'
                    options.secure = true
                if typeof options.domain is 'object'
                    host = options.domain.hostname || options.domain.host
                    if host
                        newHost = host.replace /^[^\.]+(\.[^\.]+\.[^\.]+)$/g, '$1'
                        if host is newHost
                            delete options.domain
                        else
                            options.domain = newHost
                params = arguments
                params[2] = options
                cookie.apply @, params


        # Templates directory
        app.set 'views', __dirname + '/../../views'

        # Add config.json configuration
        deepextend config, localConfig._store
        if customConfig
            deepextend config, customConfig

        # Initialize packages
        MailPackage.init()

        # This is only execute on wornet-tasks node. It's only this node that execute tasks, not the cluster
        # Start tasks
        # glob __dirname + '/../tasks/*.coffee', (er, files) ->
        #     files.map require

        # Prettify or minify the HTML output as configured
        app.locals.pretty = true if config.wornet.prettyHtml

        # Assets images in stylus code
        ['png', 'jpg', 'gif'].forEach (ext) ->
            stylus.functions[ext] = (url) ->
                functions[ext](url, config.wornet.asset.image.base64Limit)
            stylus.functions['big' + ucfirst(ext)] = (url) ->
                functions[ext](bigImg(url), config.wornet.asset.image.base64Limit)
        stylus.functions.bigImg = bigImg
        stylus.functions.quote = quoteString

        # Available s() in stylus files
        stylus.functions.s = functions.s

        # Initialize DB
        mongoUri = process.env.MONGODB_URI || do ->
            host = (process.env.DB_HOST || config.wornet.db.host) + ':' + (process.env.DB_PORT || config.wornet.db.port || 27017)
            basename = process.env.DB_BASENAME || config.wornet.db.basename
            'mongodb://' + host + '/' + basename
        mongoHostAndPort = mongoUri.split(/\//g)[2]

        console['log'] 'Mongoose connection to ' + mongoHostAndPort
        mongoose.connect mongoUri

        mongoose.connection.once 'open', ->
            console['log'] 'Mongoose default connection open to ' + mongoHostAndPort

        mongoose.connection.on 'connected', ->
            console['log'] 'Mongoose default connection connected to ' + mongoHostAndPort

        mongoose.connection.on 'error', (err) ->
            console['log'] 'Mongoose default connection error: ' + err

        mongoose.connection.on 'disconnected', ->
            console['log'] 'Mongoose default connection disconnected'

        process.on 'SIGINT', ->
            mongoose.connection.close ->
                console['log'] 'Mongoose default connection disconnected through app termination'
                process.exit 0

        deepextend localConfig._store, middleware: logger: module: arguments: [
            "combined",
            skip: (req, res) ->
                global.muteLog or (! config.env.development and res.statusCode < 400)
        ]

        next null, localConfig
