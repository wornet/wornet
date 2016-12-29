'use strict'

locks = {}

PlusWPackage =

    put: (req, res, end) ->
        statusReq = req.data.status

        next = (status, isAShare = false) =>
            idStatus = status._id
            hashedIdUser = req.user.hashedId
            at = if req.data.at
                req.data.at
            else if status and status.at and status.at.hashedId
                status.at.hashedId
            else null

            if 'undefined' is typeof locks[hashedIdUser + '-' + idStatus]
                locks[hashedIdUser + '-' + idStatus] = true
                @checkRights req, res, status, true, false, isAShare, (err, ok) =>
                    if ok
                        PlusW.create
                            user: req.user._id
                            status: idStatus
                        , (err, plusW) =>
                            delete locks[hashedIdUser + '-' + idStatus]
                            usersToNotify = []
                            hashedIdAuthor = status.author.hashedId
                            #usersToNotify contains hashedIds tests in notify.
                            #It will be transformed just before NoticePackage calling
                            unless equals hashedIdUser, hashedIdAuthor
                                if !status.author.accountConfidentiality is "public" or req.user.friends.column('hashedId').contains hashedIdAuthor
                                    usersToNotify.push hashedIdAuthor
                            unless [null, hashedIdAuthor, hashedIdUser].contains at
                                if status.at and !status.at.accountConfidentiality is "public" or req.user.friends.column('hashedId').contains at
                                    usersToNotify.push at
                            unless empty usersToNotify
                                @notify usersToNotify, statusReq, req.user
                            end null
                    else
                        delete locks[hashedIdUser + '-' + idStatus]
                        end err
            else
                end null

        if statusReq.isAShare and statusReq.referencedStatus
            Status.findOne
                _id: statusReq.referencedStatus
            , (err, originalStatus) ->
                warn err if err
                unless originalStatus
                    res.serverError new PublicError "Le status originel est introuvable."
                else
                    originalStatus.populateUsers (statusPopulated) ->
                        next statusPopulated, true
        else
            next statusReq



    delete: (req, res, end) ->
        statusReq = req.data.status

        next = (status, isAShare) =>
            idStatus = status._id
            idUser = req.user._id
            @checkRights req, res, status, false, false, isAShare, (err, ok) =>
                if ok
                    PlusW.remove
                        user: idUser
                        status: idStatus
                    , (err) ->
                        if err
                            end err
                        else
                            NoticePackage.unnotify
                                action: 'notice'
                                notice:
                                    type: 'like'
                                    launcher: idUser
                                    status: idStatus
                            end null
                else
                    end err

        if statusReq.isAShare and statusReq.referencedStatus
            Status.findOne
                _id: statusReq.referencedStatus
            , (err, originalStatus) ->
                warn err if err
                unless originalStatus
                    res.serverError new PublicError "Le status originel est introuvable."
                else
                    originalStatus.populateUsers (statusPopulated) ->
                        next statusPopulated, true
        else
            next statusReq


    checkRights: (req, res, status, liking, onlySeeing = false, isAShare = false, done) ->
        if 'function' is typeof onlySeeing
            done = onlySeeing
            onlySeeing = false
            isAShare = false
        if 'function' is typeof isAShare
            done = isAShare
            isAShare = false

        idStatus = status._id
        #already liked or disliked?
        next = ->
            wherePlus =
                user: req.user._id
                status: idStatus
            PlusW.count wherePlus, (err, count) ->
                done null, !err and liking is !count
        #if the status is mine or on my wall
        right = if req.user
            if (status.author and equals(status.author.hashedId, req.user.hashedId)) or (status.at and equals(status.at.hashedId, req.user.hashedId)) or isAShare
                true
            else
                false
        else
            if status.at
                status.at.accountConfidentiality is 'public'
            else
                status.author.accountConfidentiality is 'public'
        if right
            if onlySeeing
                done null, true
            else
                next()
        else
            req.getFriends (err, friends, friendAsks) ->
                friendsList = friends.column('_id')
                Follow.find
                    follower: req.user._id
                , (err, follows) ->
                    warn err if err
                    followed = follows.column('followed')
                    friendsListWithFollow = friendsList.copy()
                    friendsListWithFollow.merge followed
                    #The status is on the wall of a friend or a following
                    whereStatus =
                        _id: idStatus
                        $or: [
                            at: $in: friendsListWithFollow
                        ,
                            at: null
                            author: $in: friendsListWithFollow
                        ]
                    Status.count whereStatus, (err, countStatut) ->
                        if err
                            done err, false
                        else if !countStatut
                            done new PublicError s("Vous n'avez pas accès à ce statut"), false
                        else
                            if onlySeeing
                                done null, true
                            else
                                next()

    notify: (usersToNotify, status, liker) ->

        img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: liker
        statusPlace = status.at || status.author
        generateNotice = (text) ->
            [
                img +
                jd 'span(data-href="/user/status/' + status._id + '") ' +
                    text
            ]
        likersFriends = liker.friends.column 'hashedId'
        for userToNotify in usersToNotify
            notice = if userToNotify is statusPlace.hashedId
                generateNotice s("{username} a aimé une publication de votre profil.", username: liker.name.full)
            else if userToNotify is status.author.hashedId and userToNotify isnt liker.hashedId
                generateNotice if likersFriends.contains userToNotify
                    s("{username} a aimé votre publication.", username: liker.name.full)
                else
                    s("{username}, ami de {placename}, a aimé votre publication.", {username: liker.name.full, placename:statusPlace.name.full })
            else
                null

            if notice
                notice.push 'like', liker._id, status._id, cesarRight statusPlace.hashedId
                NoticePackage.notify [cesarRight userToNotify], null,
                    action: 'notice'
                    author: liker
                    notice: notice


    get: (req, res, status, done) ->
        StatusPackage.getOriginalStatus status, (err, originalStatus) =>
            warn err if err
            @checkRights req, res, originalStatus, false, true, status.isAShare, (err, ok) ->
                if !err and ok
                    status = originalStatus
                    offset = req.data.offset
                    where = status: status._id
                    .with if offset
                        _id: $gt: new ObjectId(offset).path
                    PlusW.find where
                        .limit config.wornet.limits.likersPageCount
                        .sort createdAt: 'desc'
                        .exec (err, plusWs) ->
                            if err
                                done err
                            else if !plusWs or !plusWs.length
                                done null, []
                            else
                                likersId = plusWs.map (plusW) ->
                                    plusW.user
                                User.find
                                    _id: $in: likersId
                                , (err, users) ->
                                    if err
                                        done err
                                    else if !users or !users.length
                                        done null, []
                                    else
                                        users = users.map (user) ->
                                            user.publicInformations()
                                        for user in users
                                            for plusW in plusWs
                                                if strval(plusW.user) is strval(cesarRight(user.hashedId))
                                                    user.plusWId = plusW._id
                                        done null, users
                else
                    done err

module.exports = PlusWPackage
