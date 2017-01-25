'use strict'

syncUserPhotos = (userModifications, photo) ->
    userModifications.photoId = photo.id
    userModifications.photo = photo.photo
    userModifications.thumb = photo.thumb
    for size in config.wornet.thumbSizes
        userModifications['thumb' + size] = photo['thumb' + size]
    userModifications

module.exports = (router) ->

    router.get '', (req, res) ->
        res.redirect '/' + req.user.uniqueURLID
        # UserPackage.renderProfile req, res

    router.get '/:id/:name', (req, res) ->
        cache 'publicAccountByHashedId-' + req.params.id, null, (dataCache) ->
            if dataCache['publicAccountByHashedId-' + req.params.id]
                res.redirect '/' + dataCache['publicAccountByHashedId-' + req.params.id]
            else
                findOne User,
                    _id: cesarRight req.params.id
                , (err, user) ->
                    memSet 'publicAccountByHashedId-' + req.params.id, user.uniqueURLID
                    memSet 'publicAccountByUrlId-' + user.uniqueURLID, req.params.id
                    res.redirect '/' + user.uniqueURLID
        # res.locals.friendAsked = req.flash 'friendAsked'
        # UserPackage.renderProfile req, res, req.params.id

    router.post '/edit', (req, res) ->
        # When user edit his profile
        userModifications = UserPackage.getUserModificationsFromRequest req
        next = ->
            updateUser req, userModifications, (err) ->
                if err
                    req.flash 'profileErrors', err
                res.redirect '/' + req.user.uniqueURLID
            ###
            User.findById req.user.id, (err, user) ->
                if user
                    extend user, userModifications
                    user.save (err, user) ->
                        if err
                            throw err
                if err
                    throw err
            ###
        if userModifications.photoId
            where = _id: userModifications.photoId
            values = status: 'published'
            options = safe: true
            Photo.findOneAndUpdate where, values, options, (err, photo) ->
                if ! err and photo
                    findOne Album,
                        _id: photo.album
                    , (err, album) ->
                        if !err and album
                            UserAlbums.touchAlbum req.user, album._id, (err, result) ->
                                if err
                                    warn err
                            album.refreshPreview done
                    done = ->
                        PhotoPackage.forget req, photo.id
                        syncUserPhotos userModifications, photo
                else
                    req.flash 'profileErrors', s("La photo a expirée, veuillez la ré-envoyer.")
                    delete userModifications.photoId
                next()
        else
            next()

    router.post '/photo', (req, res) ->
        photoId = req.data.photoId

        if photoId
            end = (photo) ->
                PhotoPackage.forget req, photo.id
                data = album: photo.album
                updateUser req, syncUserPhotos(data, photo), (err) ->
                    if err
                        res.serverError err
                    else
                        res.json src: photo.photo

            parallel
                album: (done) ->
                    data =
                        user: req.user._id
                    if req.user.photoAlbumId
                        data._id = req.user.photoAlbumId
                    else
                        data.name = photoDefaultName()
                    findOne Album, data, (err, album) ->
                        if !err and album
                            done null, album
                        else
                            done err
                photo: (done) ->
                    findOne Photo,
                        _id: photoId
                    , (err, photo) ->
                        if !err and photo
                            done null, photo
                        else
                            done err
                , (results) ->
                    if equals results.photo.album, results.album.id
                        end results.photo
                    else
                        addPhoto req, results.photo, null, (err, album, newPhoto) ->
                            if err
                                res.serverError err
                            else
                                Photo.findOneAndUpdate
                                    _id: newPhoto._id
                                ,
                                    status: "published"
                                ,
                                    safe: true
                                , (err, photo) ->
                                    if err
                                        res.serverError err
                                    else
                                        album.refreshPreview (err) ->
                                            if err
                                                warn err
                                        end photo
                , (err) ->
                    res.serverError err
        else
            res.serverError new PublicError s('Aucune photo selectionnée.')

    router.put "/follow", (req, res) ->
        userHashedId = req.data.hashedId
        if userHashedId
            userId = cesarRight userHashedId
            isAPublicAccount req, userHashedId, true, (err, isAPublicAccount) ->
                if isAPublicAccount and req.user
                    Follow.count
                        follower: req.user.id
                        followed: userId
                    , (err, existingFollow) ->
                        warn err if err
                        unless existingFollow
                            Follow.create
                                follower: req.user.id
                                followed: userId
                            , (err, follow) ->
                                warn err if err
                                today = (new Date).midnight()
                                id = Math.floor(today.getTime() / 1000).toString(16) + "0000000000000000"
                                img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: req.user
                                Notice.findOne
                                    user: userId
                                    type: 'follow_count'
                                    _id: $gt: id
                                , (err, noticeCount) ->
                                    warn err if err
                                    if noticeCount
                                        Notice.findOneAndUpdate
                                            _id: noticeCount._id
                                        ,
                                            $inc: count: 1
                                            status: "unread"
                                        , (err) ->
                                            warn err if err
                                            notice = [
                                                img +
                                                jd 'span ' +
                                                    s("{count} personnes ont commencé à vous suivre.", count: noticeCount.count + 1)
                                            , 'follow_count', req.user._id, null, req.user._id, noticeCount.count + 1]
                                            NoticePackage.updateNotice [userId], null,
                                                action: 'notice'
                                                notice: notice
                                                id: strval noticeCount._id
                                    else
                                        Notice.count
                                            user: userId
                                            type: 'follow'
                                            _id: $gt: id
                                        , (err, count) ->
                                            warn err if err
                                            if count and count >= 2
                                                Notice.remove
                                                    user: userId
                                                    type: 'follow'
                                                    _id: $gt: id
                                                , (err) ->
                                                    notice = [
                                                        img +
                                                        jd 'span ' +
                                                            s("{count} personnes ont commencé à vous suivre.", count: count + 1)
                                                    , 'follow_count', req.user._id, null, req.user._id, count + 1]
                                                    NoticePackage.notify [userId], null,
                                                        action: 'notice'
                                                        author: req.user._id
                                                        notice: notice
                                            else
                                                notice = [
                                                    img +
                                                    jd 'span(data-href="/' + req.user.uniqueURLID + '") ' +
                                                        s("{username} a commencé à vous suivre.", username: req.user.name.full )
                                                , 'follow', req.user._id, null, req.user._id]
                                                NoticePackage.notify [userId], null,
                                                    action: 'notice'
                                                    author: req.user._id
                                                    notice: notice

                                UserPackage.refreshFollows req, (err) ->
                                    warn err if err
                                    if !req.data.returnSuggest
                                        res.json()
                                    else
                                        UserPackage.findNextRandomPublic req, req.body.alreadyPresent.map(cesarRight), (publicUser) ->
                                            if publicUser
                                                res.json newUser: publicUser
                                            else
                                                res.json()
                                            #update suggestList
                                            UserPackage.randomPublicUsers req.user.id, true, ->
                        else
                            res.serverError new PublicError s('Vous suivez déjà ce compte.')
                else
                    res.serverError new PublicError s('Seuls les comptes publics peuvent être suivis.')
        else
            res.serverError new PublicError s('Personne à suivre.')

    router.put "/hideSuggest", (req, res) ->
        userHashedId = req.data.hashedId
        if userHashedId
            isAPublicAccount req, userHashedId, true, (err, isAPublicAccount) ->
                if isAPublicAccount and req.user
                    if UserPackage.hiddenSuggests[req.user.id]
                        UserPackage.hiddenSuggests[req.user.id].push cesarRight userHashedId
                    else
                        UserPackage.hiddenSuggests[req.user.id] = [cesarRight userHashedId]
                    redisClientEmitter.publish config.wornet.redis.defaultChannel,
                        JSON.stringify(
                            type: "addHiddenSuggest",
                            message:
                                userHashedId: userHashedId,
                                me: req.user.id
                        )
                    delay config.wornet.suggests.removeHiddenSuggest.minutes, ->
                        if UserPackage.hiddenSuggests[req.user.id]
                            index = UserPackage.hiddenSuggests[req.user.id].indexOf cesarRight userHashedId
                            if index > -1
                                UserPackage.hiddenSuggests[req.user.id].splice index, 1
                    UserPackage.findNextRandomPublic req, req.body.alreadyPresent.map(cesarRight), (publicUser) ->
                        if publicUser
                            res.json newUser: publicUser
                        else
                            res.json()
                        #update suggestList
                        UserPackage.randomPublicUsers req.user.id, true, ->

    router.delete "/follow", (req, res) ->
        userId = req.data.hashedId
        if userId
            Follow.remove
                follower: req.user.id
                followed: cesarRight userId
            , (err, follow) ->
                warn err if err
                res.json()
        else
            res.serverError new PublicError s('Personne à unfollow.')
