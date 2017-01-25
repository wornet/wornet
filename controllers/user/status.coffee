'use strict'

module.exports = (router) ->

    router.post '/recent/:id', (req, res) ->
        StatusPackage.getRecentStatusForRequest req, res, req.params.id, chat: []

    router.post '/recent', (req, res) ->
        StatusPackage.getRecentStatusForRequest req, res, null, chat: []

    router.post '/and/chat/:updatedAt/:id', (req, res) ->
        StatusPackage.getRecentStatusForRequest req, res, req.params.id, null, req.params.updatedAt

    router.post '/and/chat/:updatedAt', (req, res) ->
        StatusPackage.getRecentStatusForRequest req, res, null, null, req.params.updatedAt

    router.delete '/:id', (req, res) ->
        if !req.user
            res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
        # We cannot use findOneAndRemove because it does not execute pre-remove hook
        me = req.user._id
        next = (status) ->
            # unless equals status.author, me
            #    NoticePackage.notify [status.author], null,
            #        action: 'notice'
            #        notice: [s("{name} a supprimé un statut que vous aviez posté sur son profil.", name: req.user.fullName)]
            res.json deletedStatus: status

        switch req.params.id

            when StatusPackage.DEFAULT_STATUS_ID
                updateUser req, firstStepsDisabled: true, ->
                res.json()

            else
                findOne Status,
                    _id: req.params.id
                    $or: [
                        at: me
                    ,
                        author: me
                    ]
                , (err, status) ->
                    if err
                        res.serverError err
                    else unless status
                        res.serverError standartError()
                    else
                        deleteStatus = ->
                            status.remove (err) ->
                                if err
                                    res.serverError err
                                else
                                    StatusPackage.updatePoints req, status, status.author, false, ->
                                        next status
                        if status.shares.length
                            Status.remove
                                _id: $in: status.shares
                            , (err) ->
                                warn err if err
                                deleteStatus()
                        else if status.isAShare and status.referencedStatus
                            findOne Status,
                                _id: status.referencedStatus
                            , (err, originalStatus) ->
                                warn err if err
                                if originalStatus
                                    newShares = []
                                    for share in originalStatus.shares
                                        unless equals share, status._id
                                            newShares.push share
                                    Status.update
                                        _id: originalStatus._id
                                    ,
                                        shares: newShares
                                    , (err) ->
                                        warn err if err
                                        deleteStatus()
                                else
                                    res.serverError new PublicError s("Le status original est introuvable.")
                        else
                            deleteStatus()


    router.put '/add/:updatedAt/:id', (req, res) ->
        if !req.user
            res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
        StatusPackage.put req, res, (status) ->
            StatusPackage.getRecentStatusForRequest req, res, req.params.id, newStatus: status, req.params.updatedAt

    router.put '/add/:updatedAt', (req, res) ->
        if !req.user
            res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
        StatusPackage.put req, res, (status) ->
            StatusPackage.getRecentStatusForRequest req, res, null, newStatus: status, req.params.updatedAt

    router.post '/', (req, res) ->
        if !req.user
            res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
        if req.data.status and req.user
            Status.update
                _id: req.data.status._id
                author: req.user.id
            ,
                content: req.data.status.content || ""
                videos: req.data.status.videos || []
                links: req.data.status.links || []
            , (err, status) ->
                if err
                    res.serverError err
                else if !status
                    res.serverError new PublicError s("Vous n'avez pas le droit de modifier ce statut")
                else
                    res.json()
        else
            res.serverError new PublicError s('Pas de statut à modifier')

    router.get '/:id', (req, res) ->
        id = req.params.id
        if id
            findOne Status,
                _id: id
            , (err, status) ->
                if err
                    res.serverError err
                else
                    status.populateUsers (status) ->
                        if StatusPackage.checkRightToSee(req, status)
                            status.concernMe = if req.user
                                status.author.hashedId is req.user.hashedId or (status.at and status.at.hashedId is req.user.hashedId)
                            else
                                false
                            status.isMine = if req.user
                                equals status.author.hashedId, req.user.hashedId
                            else
                                false
                            PlusW.find
                                status: id
                            , (err, result) ->
                                tabLike = []
                                tabLike[id] ||= {likedByMe: false, nbLike: 0, likers:[]}
                                for like in result
                                    tabLike[id].nbLike++
                                    tabLike[id].likers.push like.user
                                    if req.user and equals req.user.id, like.user
                                        tabLike[id].likedByMe = true
                                status.likedByMe = tabLike[id].likedByMe
                                status.nbLike = tabLike[id].nbLike
                                status.nbImages = status.images.length
                                status.nbShare = status.shares.length
                                if status.images.length
                                    for image in status.images
                                        if -1 isnt image.src.indexOf "200x"
                                            image.src =image.src.replace "200x", ""
                                next = ->
                                    res.render 'user/status',
                                        status: status
                                        myPublicInfos: req.user.publicInformations()
                                if status.nbLike
                                    User.find
                                        _id: $in: tabLike[id].likers
                                    .skip 0
                                    .limit config.wornet.limits.maxLikersPhotoDisplayed
                                    .exec (err, likers) ->
                                        warn err if err
                                        if likers
                                            status.likers = likers.map (user) ->
                                                user.publicInformations()
                                            next status
                                        else
                                            status.likers = []
                                            next status
                                else
                                    status.likers = []
                                    next status

                        else
                            res.notFound()
        else
            res.serverError new PublicError s('Pas de statut à afficher')

    router.put '/share', (req, res) ->
        if !req.user
            res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
        user = req.user
        statusId = req.data.statusId
        if statusId
            statusToCreate =
                author: user.id
                at: null
                isAShare: true
            findOne Status,
                _id: statusId
            , (err, statusShared) ->
                warn err if err
                if statusShared
                    StatusPackage.getOriginalStatus statusShared, (err, originalStatus) ->
                        warn err if err
                        statusToCreate.referencedStatus = originalStatus._id
                        accountTocheck = if originalStatus.at
                            originalStatus.at.hashedId
                        else
                            originalStatus.author.hashedId

                        isAPublicAccount req, accountTocheck, true, (err, isAPublicAccount) ->
                            if isAPublicAccount
                                Status.create statusToCreate, (err, status) ->
                                    warn err if err
                                    if originalStatus.shares
                                        newShares = originalStatus.shares.copy()
                                        newShares.push status._id
                                    else
                                        newShares = [status._id]
                                    Status.update
                                        _id: originalStatus._id
                                    ,
                                        shares: newShares
                                    , (err, statusCreated) ->
                                        warn err if err

                                        img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: user
                                        if originalStatus.at
                                            alreadyNoticed = false
                                            if user.friends.column('hashedId').contains originalStatus.at.hashedId
                                                notice = [
                                                    img +
                                                    jd 'span(data-href="/user/status/' + originalStatus._id + '") ' +
                                                        s("{username} a partagé une publication de votre profil.", username: user.name.full)
                                                , 'share', user._id, originalStatus._id, cesarRight originalStatus.at.hashedId]
                                                NoticePackage.notify [cesarRight originalStatus.at.hashedId], null,
                                                    action: 'notice'
                                                    author: user._id
                                                    notice: notice
                                            else
                                                Notice.findOne
                                                    type: 'share_count'
                                                    attachedStatus: originalStatus._id
                                                    place: cesarRight originalStatus.at.hashedId
                                                , (err, existingNotice) ->
                                                    warn err if err
                                                    if existingNotice and existingNotice.count
                                                        notice = [
                                                            img +
                                                            jd 'span(data-href="/user/status/' + originalStatus._id + '") ' +
                                                                s("{number} personnes ont partagé une publication de votre profil.", number: existingNotice.count + 1)
                                                        , 'share_count', user._id, originalStatus._id, cesarRight originalStatus.at.hashedId, existingNotice.count + 1]
                                                        Notice.update
                                                            _id: existingNotice._id
                                                        ,
                                                            $inc: count: 1
                                                        , (err, noticeUpdated) ->
                                                            warn err if err
                                                            alreadyNoticed = true
                                                            NoticePackage.updateNotice [cesarRight originalStatus.at.hashedId], null,
                                                                action: 'notice'
                                                                notice: notice

                                                    else
                                                        notice = [
                                                            img +
                                                            jd 'span(data-href="/user/status/' + originalStatus._id + '") ' +
                                                                s("L'une de vos publications a été partagée {number} fois.", number: 1)
                                                        , 'share_count', user._id, originalStatus._id, cesarRight(originalStatus.at.hashedId), 1]
                                                        NoticePackage.notify [cesarRight originalStatus.at.hashedId], null,
                                                            action: 'notice'
                                                            author: user._id
                                                            notice: notice

                                        if originalStatus.author
                                            if user.friends.column('hashedId').contains originalStatus.author.hashedId
                                                notice = [
                                                    img +
                                                    jd 'span(data-href="/user/status/' + originalStatus._id + '") ' +
                                                        s("{username} a partagé votre publication.", username: user.name.full)
                                                , 'share', user._id, originalStatus._id, cesarRight originalStatus.author.hashedId]
                                                NoticePackage.notify [cesarRight originalStatus.author.hashedId], null,
                                                    action: 'notice'
                                                    author: user._id
                                                    notice: notice
                                            else
                                                findOne Notice,
                                                    type: 'share_count'
                                                    attachedStatus: originalStatus._id
                                                    place: cesarRight originalStatus.author.hashedId
                                                , (err, existingNotice) ->
                                                    warn err if err
                                                    if existingNotice and existingNotice.count
                                                        notice = [
                                                            img +
                                                            jd 'span(data-href="/user/status/' + originalStatus._id + '") ' +
                                                                s("L'une de vos publications a été partagée {number} fois.", number: existingNotice.count + 1)
                                                        , 'share_count', user._id, originalStatus._id, cesarRight originalStatus.author.hashedId, existingNotice.count + 1]
                                                        Notice.update
                                                            _id: existingNotice._id
                                                        ,
                                                            $inc: count: 1
                                                            status: "unread"
                                                        , (err, noticeUpdated) ->
                                                            warn err if err
                                                            alreadyNoticed = true
                                                            NoticePackage.updateNotice [cesarRight originalStatus.author.hashedId], null,
                                                                action: 'notice'
                                                                notice: notice
                                                                id: strval existingNotice._id

                                                    else
                                                        notice = [
                                                            img +
                                                            jd 'span(data-href="/user/status/' + originalStatus._id + '") ' +
                                                                s("L'une de vos publications a été partagée {number} fois.", number: 1)
                                                        , 'share_count', user._id, originalStatus._id, cesarRight(originalStatus.author.hashedId), 1]

                                                        NoticePackage.notify [cesarRight originalStatus.author.hashedId], null,
                                                            action: 'notice'
                                                            author: user._id
                                                            notice: notice
                                        res.json()
                            else
                                res.serverError new PublicError "Vous ne pouvez pas partager ce statut."
                else
                    res.serverError new PublicError "Le statut à partager n'existe pas."
        else
            res.serverError new PublicError "Le statut à partager n'existe pas."


    router.post '/link/meta', (req, res) ->
        url = req.data.url
        httpPattern = 'http://'
        if url
            url = url.replace /^https?:\/\//g, ''
            x = xray()
            try
                x(httpPattern + url,
                    title: "title"
                    ogTitle: "meta[name='og:title']@content"
                    description: "meta[name='description']@content"
                    ogDescription: "meta[property='og:description']@content"
                    ogImage: "meta[property='og:image']@content"
                    author: "meta[name='author']@content"
                ) (err, data)->
                    res.json data: data
            catch err
                res.json()
