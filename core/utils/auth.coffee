###
Module that will handle our authentication tasks
###
"use strict"

# Set the remember cookie to recognize the users who checked the remember option
exports.remember = (res, id) ->
    res.cookie config.wornet.remember.key, id,
        maxAge: config.wornet.remember.ttl.days
        httpOnly: true
        signed: true

# Get user id remembered with cookie
exports.remembered = (req, done) ->
    id = req.cookie config.wornet.remember.key
    if id and id isnt config.wornet.remember.off
        User.findOne
            _id: id
        , (err, user) ->
            if err
                done false, err
            else
                done user, null, id
    else
        done false

# Know if the visitor if a new visitor
exports.isNewVisitor = (req) ->
    empty req.cookie config.wornet.remember.key

# Know if the visitor if a new visitor
exports.isReturningVisitor = (req) ->
    !exports.isNewVisitor(req)

# Delete user session and cookie
exports.logout = (req, res) ->
    NoticePackage.remove req.user.id
    delete res.locals.user
    delete req.user
    delete req.session.user
    delete req.session.friends
    delete req.session.friendAsks
    delete req.session.follower
    delete req.session.following
    req.cacheFlush()
    exports.remember res, config.wornet.remember.off

# Store user in session, and append to the request object
exports.auth = (req, res, user, done) ->
    unless user
        throw new Error 'Missing user, auth.auth() excpect 3 parameters: request, response, user object'
    user = objectToUser user
    res.locals.user = user
    req.user = user
    req.session.user = user
    req.getFriendsFromDataBase (err, friends, friendAsks) ->
        unless err
            user.friends = friends
            user.friendAsks = friendAsks
            req.session.friends = friends
            req.session.friendAsks = friendAsks
            user.numberOfFriends = friends.length
            Follow.find
                $or: [
                    follower: user._id
                ,
                    followed: user._id
                ]
            , (err, allFollows) ->
                iFollow = []
                iamFollowed = []
                for follow in allFollows
                    if equals follow.follower, user._id
                        iFollow.push follow.followed
                    else
                        iamFollowed.push follow.follower
                user.follower = iamFollowed
                user.following = iFollow
                req.session.follower = iamFollowed
                req.session.following = iFollow
            if typeof(done) is 'function'
                done err, user

exports.login = (req, res, done) ->
    # Retrieve the user from the database by login
    User.findOne
        email: strtolower req.body.email
    , (err, user) ->

        # If something weird happens, abort.
        if err
            req.flash "loginErrors", err unless req.xhr
            return done err

        incorrectLoginMessage = s("Veuillez vérifier votre e-mail et votre mot de passe.")
        # If we couldn't find a matching user, flash a message explaining what happened
        unless user
            req.flash "loginErrors", incorrectLoginMessage unless req.xhr
            return done incorrectLoginMessage, false

        # Make sure that the provided password matches what's in the DB.
        req.tryPassword user, (ok) ->
            if ok
                # If user ask for remember him
                if req.body.remember
                    exports.remember res, user._id

                # If everything passes, return the retrieved user object.
                exports.auth req, res, user, done
            else
                req.flash "loginErrors", incorrectLoginMessage unless req.xhr
                done incorrectLoginMessage, false


# Try to login with session data or remember cookie
exports.tryLogin = (req, res, next) ->
    req.session.reload ->
        if req.session.user?
            exports.auth req, res, req.session.user, next
        else
            exports.remembered req, (user, err, id) ->
                if user
                    exports.remember res, id
                    exports.auth req, res, user, next
                else
                    if exports.isNewVisitor req
                        res.locals.isNewVisitor = true
                    exports.remember res, config.wornet.remember.off
                    next()

###
Return true if a value is in a list (after solving jokers)
@return boolean match
###
inList = (value, list) ->
    list.contains value, (match, value) ->
        match = new RegExp match.replace(/\*\*/g, '.*').replace(/\*/g, '[^/]*')
        match.test value

###
A helper method to determine if a user has been authenticated, and if they have the right role.
If the user is not known, redirect to the login page. If the role doesn't match, show a 403 page.
@param role The role that a user should have to pass authentication.
###
exports.isAuthenticated = (req, res, next) ->
    if req.isStatic?
        if req.allowedUserId and (! req.user or req.allowedUserId isnt req.user.id)
            res.notFound()
        else
            next()
    else
        exports.tryLogin req, res, ->

            done = ->
                # Access map
                auth = [
                    "/photos"
                    "/report/**"
                    "/user/**"
                ]

                whitelist = [
                    "/user/forgotten-password"
                    "/user/reset-password"
                    "/user/login"
                    "/user/signin"
                ]

                publicAccountList = [
                    /^\/user\/albums\/medias\/[0-9a-fA-F]{24}$/
                    /^\/user\/status\/and\/chat\/[0-9a-fA-F]{24}|0\/?([0-9a-fA-F]{24})?$/
                    /^\/user\/albums$/
                    /^\/user\/plusW\/list$/
                    /^\/user\/comment$/
                    /^\/user\/friend\/list$/
                    /^\/user\/following\/list$/
                    /^\/user\/follower\/list$/
                    /^\/user\/photo\/[0-9a-fA-F]{24}$/
                    /^\/user\/status\/[0-9a-fA-F]{24}$/
                    /^\/user\/directory$/
                ]

                admin = [
                    "/admin"
                ]

                adminIfNotEnabled = (conf, route) ->
                    if conf
                        auth.push route
                    else
                        admin.push route

                adminIfNotEnabled config.wornet.agenda and config.wornet.agenda.enabled, '/agenda'
                adminIfNotEnabled config.wornet.app and config.wornet.app.enabled, '/user/app'

                res.locals.noIndex = false
                route = req.url
                # Get user role (in any user connected : empty string)
                role = (if (req.user and req.user.role) then req.user.role else "")

                nextStep = (isARouteForPublicAccount) ->
                    # If the URL is in the access restricted list
                    if inList route, admin
                        if role is 'admin'
                            res.locals.noIndex = true
                            next()
                        else
                            model = url: route
                            res.unautorized model
                    else if isARouteForPublicAccount
                        next()
                    else if inList(route, auth) and ! inList(route, whitelist)
                        # If any user are connected
                        if req.user
                            res.locals.noIndex = true
                            next()
                        else
                            # If the user is not authorized, save the location that was being accessed so we can redirect afterwards.
                            isARouteWithoutMessage = (route is '/')
                            if req.isJSON
                                if isARouteWithoutMessage
                                    res.serverError new PublicError s("Connectez-vous pour accéder à cette page.")
                                else
                                    res.json goingTo: req.url
                            else
                                req.goingTo req.url
                                if isARouteWithoutMessage
                                    req.flash "loginErrors", new PublicError s("Connectez-vous pour accéder à cette page.")
                                res.redirect "/"
                    else
                        next()

                isARouteForPublicAccount = false
                for regexp in publicAccountList
                    if regexp.test route
                        isARouteForPublicAccount = true
                        regexpToTest = regexp
                if isARouteForPublicAccount
                    route.replace regexpToTest, (all, hashedId) ->
                        if hashedId
                            isAPublicAccount req, hashedId, true, (err, isAPublicAccount) ->
                                if err and err instanceof Error and err.message is "NOTAUSERID"
                                    nextStep true
                                else
                                    nextStep isAPublicAccount
                        else
                            nextStep true
                else
                    nextStep false

            if req.user
                unless req.url is '/user/notify'
                    req.user.lastActivity = new Date
                    req.user.save()
                req.getFriends (err, friends, friendAsks) ->
                    friends.each ->
                        present = NoticePackage.isPresent @id
                        if @present isnt present
                            @present = present
                    req.user.friends = friends
                    friendIds = friends.column 'id'
                    for id, friend of friendAsks
                        if friendIds.contains friend.id
                            delete friendAsks[id]
                    req.user.friendAsks = friendAsks
                    req.user.numberOfFriends = friends.length
                    req.session.user.friendAsks = friendAsks
                    req.session.user.friends = friends
                    req.session.friendAsks = friendAsks
                    req.session.friends = friends
                    req.session.user.numberOfFriends = friends.length
                    Follow.find
                        $or: [
                            follower: req.user.id
                        ,
                            followed: req.user.id
                        ]
                    , (err, allFollows) ->
                        iFollow = []
                        iamFollowed = []
                        for follow in allFollows
                            if equals follow.follower, req.user.id
                                iFollow.push follow.followed
                            else
                                iamFollowed.push follow.follower
                        req.user.follower = iamFollowed
                        req.user.following = iFollow
                        req.session.follower = iamFollowed
                        req.session.following = iFollow
                        if err
                            res.serverError err
                        else
                            req.session.notifications ||= []
                            done()
            else
                done()
