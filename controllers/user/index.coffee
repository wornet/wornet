'use strict'

UserErrors =
    INVALID_DATE: s("Veuillez entrer votre date de naissance au format jj/mm/aaaa ou aaaa-mm-jj.")
    WRONG_EMAIL: s("Cette adresse e-mail n'est pas disponible (elle est déjà prise ou la messagerie n'est pas compatible ou encore son propriétaire a demandé à ne plus recevoir d'email de notre part).")
    INVALID_PASSWORD_CONFIRM: s("Veuillez entrer des mots de passe identiques.")
    AGREEMENT_REQUIRED: s("Veuillez prendre connaissance et accepter les conditions générales d’utilisation et la politique de confidentialité.")
    PRE_REGISTER: s("Inscriptions limitées aux-préinscrits jusqu'au 16 février. Vous êtes invité à vous réinscrire à cette date.")
    MISSING_SEX: s("Veuillez indiquer si vous êtes un homme ou une femme.")

module.exports = (router) ->

    directoryPublicUsers = []
    directoryLastRetreive = 0
    templateFolder = 'user'
    signinUrl = '/user/signin'


    if config.env.development
        router.get '/test/sms', (req, res) ->
            titre = "Super Event Trop Genial"
            url = "https://www.wornet.net/move/event/98413141316987"
            NoticePackage.notify [req.user._id], null,
                action: 'sms'
                author: req.user._id
                notice: ["Je viens de créer l'évènement " + titre + " rejoins moi vite en cliquant ici : " + url, "sms"]


    pm = new PagesManager router, templateFolder

    # When user submit his e-mail and password to log in
    router.post '/login', (req, res) ->
        # Log in user
        auth.login req, res, (err, user) ->
            url = (req.goingTo() if user) || '/'
            # With AJAX, send JSON
            if req.xhr
                if err
                    res.serverError err, true
                else
                    # url to be redirected in goingTo key of the JSON object
                    res.json goingTo: url
            # Without AJAX, normal redirection even if an error occured
            else
                res.redirect url

    # When user click on a logout link/button
    router.get '/logout', (req, res) ->
        # Save goingTo to return to the previous page after reconnect
        model = {}
        auth.logout req, res
        if req.body.goingTo?
            req.goingTo req.body.goingTo
        res.redirect '/'

    # When signin step 2 page displays
    pm.page '/signin', (req) ->
        # Get errors in flash memory (any if AJAX is used and works on client device)
        userTexts: userTexts()
        signinAlerts: req.getAlerts 'signin' # Will be removed when errors will be displayed on the next step

    router.get '/signin/with/:email', (req, res) ->
        res.render 'user/signin',
            email: req.params.email
            userTexts: userTexts()
            signinAlerts: req.getAlerts 'signin'

    # When user submit his e-mail and password to sign in
    router.put '/signin', (req, res) ->
        email = req.body.email.toLowerCase()
        model = {}
        # A full name must contains a space but is not needed at the first step
        # if req.body.name? and req.body.name.full.indexOf(' ') is -1
        #     req.flash 'signinErrors', s("Veuillez entrer vos prénom et nom séparés d'un espace.")
        #     res.redirect signinUrl
        # Passwords must be identic
        if config.wornet.mail.hostsBlackList.indexOf(email.replace(/^.*@([^@]*)$/g, '$1')) isnt -1
            req.flash 'signinErrors', UserErrors.WRONG_EMAIL
            res.redirect signinUrl
        else if req.body.password isnt req.body.passwordCheck and req.body.step is "2"
            req.flash 'signinErrors', UserErrors.INVALID_PASSWORD_CONFIRM
            res.redirect signinUrl

        # Pre-Registration
        # else if (new Date) < new Date("2015-02-16") and ! count and ! require(__dirname + '/../../core/system/preRegistration')().contains email
        #     req.flash 'signinErrors', UserErrors.PRE_REGISTER
        #     res.redirect signinUrl

        # If no error
        else if req.body.step is "2"
            if empty req.body.legals
                req.flash 'signinErrors', UserErrors.AGREEMENT_REQUIRED
                res.redirect signinUrl
            else unless req.body.sex in ['man', 'woman']
                req.flash 'signinErrors', UserErrors.MISSING_SEX
                res.redirect signinUrl
            else
                createURLID = (next) ->
                    urlIdTotest = replaceAccent (req.body['name.first'] + '.' + req.body['name.last']).toLowerCase() + '.' + Math.floor Math.random() * config.wornet.limits.urlId
                    User.count
                        uniqueURLID: urlIdTotest
                    , (err, count) ->
                        warn err if err
                        if count
                            createURLID next
                        else
                            next urlIdTotest
                User.count
                    uniqueURLID: replaceAccent (req.body['name.first'] + '.' + req.body['name.last']).toLowerCase()
                , (err, count) ->
                    warn err if err
                    next = (urlId) ->
                        # A full name must contains a space but is not needed at the first step
                        User.create
                            name:
                                first: req.body['name.first']
                                last: req.body['name.last']
                            registerDate: new Date
                            email: req.body.email
                            password: req.body.password
                            sex: req.body.sex
                            birthDate: inputDate req.body.birthDate
                            uniqueURLID: urlId
                        , (saveErr, user) ->
                            if saveErr
                                switch (saveErr.code || 0)
                                    when Errors.DUPLICATE_KEY
                                        req.flash 'signinErrors', UserErrors.WRONG_EMAIL
                                    else
                                        err = saveErr.err || strval(saveErr)
                                        valErr = 'ValidationError:'
                                        if err.indexOf(valErr) is 0
                                            err = s("Erreur de validation :") + err.substr(valErr.length)
                                            errors =
                                                'invalid first name': s("prénom invalide")
                                                'invalid last name': s("nom invalide")
                                                'invalid birth date': s("date de naissance invalide")
                                                'invalid phone number': s("numéro de téléphone invalide")
                                                'invalid e-mail address': s("adresse e-mail invalide")
                                            for code, message of errors
                                                err = err.replace code, message
                                        req.flash 'signinErrors', err
                                res.redirect signinUrl
                            else
                                Album.create
                                    name: "Téléchargements"
                                    user: user._id
                                , (err, album) ->
                                    warn err if err
                                    if album
                                        User.update
                                            _id: user._id
                                        ,
                                            photoUploadAlbumId: album._id
                                        , (err, nbModif) ->
                                            warn err if err
                                            user.photoUploadAlbumId = album._id
                                            # if "Se souvenir de moi" est coché
                                            if req.body.remember?
                                                auth.remember res, user._id
                                            # Put user in session
                                            auth.auth req, res, user, ->
                                                res.redirect if user then '/user/welcome' else signinUrl
                                                unless user.role is 'confirmed'
                                                    confirmUrl = config.wornet.protocole +  '://' + req.getHeader 'host'
                                                    confirmUrl += '/user/confirm/' + user.hashedId + '/' + user.token
                                                    message = jdMail 'welcome',
                                                        email: email
                                                        url: confirmUrl
                                                    MailPackage.send user.email, s("Bienvenue sur le réseau social WORNET !"), message
                                            emailUnsubscribed email, (err, unsub) ->
                                                if unsub
                                                    findOne Counter, name: 'resubscribe', (err, counter) ->
                                                        if counter
                                                            counter.inc()
                    if count
                        createURLID next
                    else
                        next replaceAccent (req.body['name.first'] + '.' + req.body['name.last']).toLowerCase()
        else
            res.redirect signinUrl
        # res.render templateFolder + '/signin', model

    forgottenPasswordUrl = '/forgotten-password'

    pm.page forgottenPasswordUrl, (req) ->
        resetPasswordAlerts: req.getAlerts 'resetPassword'

    router.post forgottenPasswordUrl, (req, res) ->
        fail = ->
            req.flash 'resetPasswordErrors', s("Réinitialisation impossible, vérifiez votre adresse e-mail et vérifiez que vous n'avez pas déjà reçu de lien de réinitialisation de Wornet.")
            res.redirect req.originalUrl
        findOne User, email: req.body.email, (err, user) ->
            if ! err and user
                ResetPassword.remove createdAt: $lt: Date.yesterday(), (err) ->
                    if err
                        warn err, req
                    ResetPassword.find user: user.id, (err, tokens) ->
                        if err or tokens.length > 1
                            fail()
                        else
                            ResetPassword.create user: user.id, (err, reset) ->
                                if err
                                    fail()
                                else
                                    resetUrl = config.wornet.protocole +  '://' + req.getHeader 'host'
                                    resetUrl += '/user/reset-password/' + user.hashedId + '/' + reset.token
                                    message = s("Si vous souhaitez choisir un nouveau mot de passe pour votre compte Wornet {email}, cliquez sur le lien ci-dessous ou copiez-le dans la barre d'adresse de votre navigateur.", email: user.email)
                                    console['log'] ['reset link', user.email, user._id, resetUrl]
                                    MailPackage.send user.email, s("Réinitialisation de mot de passe"), message + '\n\n' + resetUrl, message + '<br><br><a href="' + resetUrl + '">' + s("Réinitialiser le mot de passe de mon compte") + '</a>'
                                    req.flash 'resetPasswordSuccess', s("Un mail vous permettant de choisir un nouveau mot de passe vous a été envoyé.")
                                    res.redirect req.originalUrl
            else
                fail()

    resetPasswordUrl = '/reset-password/:user/:token'

    router.get resetPasswordUrl, (req, res) ->
        userId = cesarRight req.params.user
        ResetPassword.remove createdAt: $lt: Date.yesterday(), (err) ->
            if err
                warn err, req
            findOne ResetPassword,
                user: userId
                token: req.params.token
            , (err, reset) ->
                if reset and ! err
                    res.render 'user/reset-password', resetPasswordAlerts: req.getAlerts 'resetPassword'
                else
                    res.serverError new PublicError s("Lien invalide ou expiré")

    router.post resetPasswordUrl, (req, res) ->
        fail = (err) ->
            req.flash 'resetPasswordErrors', err
            res.redirect req.originalUrl
        if empty(req.body.password) or empty(req.body.passwordCheck)
            fail s("Veuillez entrer votre nouveau mot de passe dans les deux champs.")
        else if req.body.password isnt req.body.passwordCheck
            fail UserErrors.INVALID_PASSWORD_CONFIRM
        else
            userId = cesarRight req.params.user
            ResetPassword.remove createdAt: $lt: Date.yesterday(), (err) ->
                if err
                    warn err, req
                findOne ResetPassword,
                    user: userId
                    token: req.params.token
                , (err, reset) ->
                    if reset and ! err
                        findById User, userId, (err, user) ->
                            if user and ! err
                                user.password = req.body.password
                                user.save (err) ->
                                    if err
                                        if err and strval(err).indexOf('ValidationError:') is 0
                                            fail s("Format du mot de passe incorrect")
                                        else
                                            fail err
                                    else
                                        auth.auth req, res, user, ->
                                            req.flash 'profileSuccess', s("Mot de passe modifié avec succès.")
                                            res.redirect '/'
                                            reset.remove()
                            else
                                fail s("Lien invalide ou expiré")
                    else
                        fail s("Lien invalide ou expiré")

    router.get '/welcome', (req, res) ->
        UserPackage.randomPublicUsers req.user.id, true, 20, (publicUsers) ->
            res.render "user/welcome",
                welcomeSuggest: publicUsers

    router.put '/welcome', (req, res) ->
        usersHashedId = req.data.usersHashedId
        if usersHashedId and usersHashedId.length
            objectsToCreate = []
            for hashedId in usersHashedId
                objectsToCreate.push
                    follower: req.user.id
                    followed: cesarRight hashedId

            Follow.create objectsToCreate, (err) ->
                warn err if err
                res.json()
        else
            res.json()

    router.get '/settings', (req, res) ->
        CertificationAsk.count
            user: req.user._id
            status: $in: ["pending", "approved"]
        , (err, certif) ->
            warn err if err
            res.render 'user/settings',
                settingsAlerts: req.getAlerts 'settings'
                userTexts: userTexts()
                certifPendingOrApproved: !!certif

    router.post '/settings', (req, res) ->
        userModifications = UserPackage.getUserModificationsFromRequest req
        publicDataError = false
        newUrlId = replaceAccent req.body.uniqueURLID
        ###
        for setting in ['newsletter', 'noticeFriendAsk', 'noticePublish', 'noticeMessage']
            userModifications[setting] = !! req.body[setting]
        ###
        next = ->
            updateUser req, userModifications, (err) ->
                err = humanError err
                cache "publicAccountByHashedId-" + req.user.hashedId, null, (dataCache) ->

                    oldUrlId = dataCache["publicAccountByHashedId-" + req.user.hashedId]
                    memDel "publicAccountByUrlId-" + oldUrlId
                    memSet "publicAccountByUrlId-" + newUrlId, req.user.hashedId
                    memSet "publicAccountByHashedId-" + req.user.hashedId, newUrlId

                    save = ->
                        if userModifications.password
                            delete userModifications.password
                    if req.xhr
                        if err
                            res.serverError err
                        else
                            save()
                            res.json()
                    else
                        if err or publicDataError
                            if err instanceof PublicError
                                req.flash 'settingsErrors', err.toString()
                            else if err
                                switch err.code
                                    when 11000
                                        req.flash 'settingsErrors', s("Adresse e-mail non disponible.")
                                    else
                                        req.flash 'settingsErrors', s("Erreur d'enregistrement.")
                            else
                                req.flash 'settingsErrors', s("Erreur d'enregistrement.")
                        else
                            save()
                            req.flash 'settingsSuccess', s("Modifications enregistrées.")
                        res.redirect '/user/settings'

        treatPublic = ->
            if userModifications.accountConfidentiality is "public"
                userModifications.maskFollowList = false
                userModifications.maskFriendList = false
                unless newUrlId is req.user.uniqueURLID
                    if /^[a-zA-Z0-9_.]*$/.test newUrlId
                        User.count
                            uniqueURLID: newUrlId
                        , (err, count) ->
                            warn err if err
                            if count is 0
                                userModifications.uniqueURLID = newUrlId
                            else
                                publicDataError = true
                                req.flash 'settingsErrors', s("Personnalisation URL: Non disponible")
                            next()
                    else
                        publicDataError = true
                        req.flash 'settingsErrors', s("Personnalisation URL: Caractères acceptés : lettres non accentuées, chiffres, points et undescores")
                        next()
                else
                    next()
            else
                userModifications.allowFriendPostOnMe = true
                if req.user.certifiedAccount is true
                    CertificationAsk.update
                        user: req.user.id
                    ,
                        status: "refused"
                    ,
                        multi: true
                    , (err, certif) ->
                        warn err if err
                        userModifications.certifiedAccount = false
                Follow.remove
                    followed: req.user._id
                , (err) ->
                    warn err if err
                next()

        if !empty(req.body.actualPassword) and !empty(req.body.newPassword) and !empty(req.body.newPasswordAgain)
            if req.body.newPassword isnt req.body.newPasswordAgain
                publicDataError = true
                req.flash 'settingsErrors', s("Les nouveaux mots de passe ne correspondent pas.")
                treatPublic()
            findOne User,
                _id: req.user._id
            , (err, user) ->
                req.tryPassword user, req.body.actualPassword, (ok) ->
                    if !ok
                        publicDataError = true
                        req.flash 'settingsErrors', s("Mot de passe actuel incorrect.")
                    else
                        userModifications.password = req.body.newPassword
                    treatPublic()
        else
            treatPublic()

    toggleShutter = (req, res, opened) ->
        updateUser req, openedShutter: opened, (err) ->
            if err
                warn err
            res.json()

    router.post '/shutter/open', (req, res) ->
        toggleShutter req, res, true

    router.post '/shutter/close', (req, res) ->
        toggleShutter req, res, false

    router.get '/albums/with/:owner', (req, res) ->
        # Get albums list from the user logged in and the owner of displayed profile
        userIds = [req.user.id]
        owner = cesarRight req.params.owner
        if req.user.id isnt owner
            userIds.push owner
        else
            owner = null
        UserPackage.getAlbums userIds, (err, albums) ->
            data =
                err: err
                albums: albums[req.user.id]
            if owner
                data.withAlbums = albums[owner]
            res.json data

    router.get '/albums', (req, res) ->
        # Get albums list from the user logged in
        if req.user
            UserPackage.getAlbums [req.user.id], (err, albums) ->
                res.json
                    err: err
                    albums: albums[req.user.id]
        else
            res.json()

    router.get '/albums/medias/:hashedId', (req, res) ->
        # hashedId is me or at (of a friend)
        hashedId = req.params.hashedId
        findById User, cesarRight(req.params.hashedId), (err, user) ->
            UserPackage.getAlbumsForMedias req, hashedId, false, (err, albums, nbAlbums) ->
                res.json
                    err: err
                    albums: albums
                    nbAlbums: nbAlbums
                    user: user.publicInformations()

    router.get '/albums/:hashedId', (req, res) ->
        findById User, cesarRight(req.params.hashedId), (err, user) ->
            if user and ! err
                res.render 'user/album-list',
                    profile: user
                    isMe: req.user.hashedId is req.params.hashedId
            else
                res.notFound()

    router.get '/albums/all/:hashedId', (req, res) ->
        # hashedId is me or at (of a friend)
        hashedId = req.params.hashedId
        UserPackage.getAlbumsForMedias req, hashedId, true, (err, albums, nbAlbums) ->
            res.json
                err: err
                albums: albums
                nbAlbums: nbAlbums

    # Display images in an album
    router.get '/album/:id', (req, res) ->
        end = (model) ->
            res.render templateFolder + '/album', model
        done = (model) ->
            if model.album and model.album.isMine and req.user.photoId
                findById Photo, req.user.photoId, (err, photo) ->
                    if err
                        warn err, req
                    else if photo
                        if equals photo.album, model.album.id
                            model.album.currentPhoto = req.user.photoId
                    else
                        warn (new Error req.user.fullName + " a un photoId, mais la photo est introuvable."), req
                    end model
            else
                end model
        id = req.params.id
        album = null
        photos = null
        next = ->
            if album and photos
                photos.reverse()
                done
                    album: album
                    photos: photos
        try
            findById Album, id, (err, foundAlbum) ->
                if err or ! foundAlbum
                    res.notFound()
                else if equals foundAlbum.user, req.user.id
                    album = foundAlbum
                    album.isMine = true
                    next()
                else
                    req.getFriends (err, friends) ->
                        if err
                            res.serverError err
                        else if friends.column('_id').contains(foundAlbum.user, equals)
                            album = foundAlbum
                            album.isMine = false
                            next()
                        else
                            res.serverError new PublicError s("Cet album est privé")
            PhotoPackage.fromAlbum id, (err, foundPhotos) ->
                if err
                    res.serverError err
                else
                    photos = foundPhotos
                    next()
        catch
            res.notFound()

    router.put '/album/add', (req, res) ->
        if req.body.album and req.body.album.name is photoDefaultName()
            res.serverError new PublicError s("Ce nom est reservé.")
        else
            # Create a new album
            at = req.body.at
            album = extend user: if at
                cesarRight at
            else
                req.user._id
            , req.body.album
            album.lastEmpty = new Date
            Album.create album, (err, album) ->
                if at
                    User.update
                        _id: album.user
                    ,
                        sharedAlbumId: album._id
                    , (err, user) ->
                        warn err if err
                album.user = cesarLeft album.user
                res.json
                    err: err
                    album: album

    router.delete '/album/:id', (req, res) ->
        id = req.params.id
        me = req.user.id
        end = ->
            # we can't do parallelRemove because we have to remove the status first
            # to don't have versionError when we save status on photoSchema pre save
            Status.remove
                album: id
                $or: [
                    author: me
                ,
                    at: me
                ]
            , (err, count) ->
                if err
                    res.serverError err
                else
                    Album.remove
                        _id: id
                        user: me
                    , (err, count) ->
                        if err
                            res.serverError err
                        else
                            done = ->
                                UserAlbums.removeAlbum req.user, id, (err) ->
                                    req.flash 'profileSuccess', s("Album supprimé")
                                    res.json goingTo: '/' + req.user.uniqueURLID
                            if strval(req.user.photoAlbumId) is strval(id)
                                updateUser req, photoAlbumId: null, done
                            else if strval(req.user.sharedAlbumId) is strval(id)
                                updateUser req, sharedAlbumId: null, done
                            else
                                done()

        findById Photo, req.user.photoId, (err, photo) ->
            warn err, req if err
            if photo and ! err and equals photo.album, id
                updateUser req, photoId: null, end
            else
                end()

    # Update Album Name and description
    router.post '/album/:id', (req, res) ->
        id = req.params.id

        set = {}

        if req.data.name and req.data.name.content
            set.name = req.data.name.content
        else
            res.serverError new PublicError s("Le titre de l'album est obligatoire.")

        if req.data.name and req.data.name.content is photoDefaultName()
            res.serverError new PublicError s("Ce nom est reservé.")
        else
            if req.data.description and req.data.description.content
                set.description = req.data.description.content

            if set.getLength() isnt 0
                parallel [(done) ->
                    Status.update
                        album: id
                    ,
                        albumName: set.name
                    ,
                        multi: true
                    , done
                , (done) ->
                    Album.update
                        _id: id
                        user: req.user.id
                    ,
                        set
                    , done
                ], ->
                    res.json()
                , (err) ->
                    res.serverError err

    router.get '/album/one/:id', (req, res) ->
        findOne Album,
            _id: req.params.id
        , (err, album) ->
            if err
                res.serverError err
            else
                res.json album: album

    router.put '/video/add', (req, res) ->
        # Create a new video
        video = extend user: req.user._id, req.data.video
        Video.create video, ->
            res.json()

    router.put '/link/add', (req, res) ->
        # Create a new link
        link = extend user: req.user._id, req.data.link
        Link.create link, (err, link)->
            res.json link: link

    router.get '/photo/:id', (req, res) ->
        me = if req.user
            req.user._id
        else
            null
        findById Photo, req.params.id, (err, photo) ->
            if err
                res.serverError err
            else if photo and photo.status is 'published'
                info = photo.columns ['name']
                info.concernMe = equals(photo.user, me) or (req.session.photosAtMe || []).contains photo.id, equals
                count = 1
                next = ->
                    unless --count
                        res.json info
                if photo.album
                    count++
                    findById Album, photo.album, (err, album) ->
                        if album and ! err
                            info.album =
                                id: album._id
                                name: album.name
                            count++
                            PhotoPackage.fromAlbum album.id, (err, photos) ->
                                if err
                                    photos = []
                                info.album.photos = photos
                                next()
                            next()
                if photo.user
                    count++
                    req.getUserById photo.user, (err, user) ->
                        if user and ! err
                            info.user = user.publicInformations()
                        next()
                next()
            else
                res.notFound()

    # The user upload an image (profile photo, images in status, etc.)
    router.post '/photo', (req, res) ->
        # When user upload a new profile photo
        model = images: []
        images = req.files.photo || []
        unless images instanceof Array
            images = [images]
        done = (data, photo) ->
            model.images.push data
            if model.images.length is images.length
                model.images.reverse()
                if req.body.mediaFlag and req.body.mediaFlag is "O" and photo
                    UserPackage.setAsProfilePhoto req, res, photo, ->
                        res.render templateFolder + '/upload-photo', model
                else
                    res.render templateFolder + '/upload-photo', model
        lastestAlbum = null
        if images.length > 0
            images.each ->
                image = @
                data = name: @name
                if image.size > config.wornet.upload.maxsize
                    data.error = "size-exceeded"
                    warn data.error, req
                    done data
                else unless (['image/png', 'image/jpeg']).contains image.type
                    data.error = "wrong-format : " + image.type
                    warn data.error, req
                    done data
                else
                    album =  req.body.album || 0
                    next = ->
                        addPhoto req, image, album, (err, createdAlbum = null, photo) ->
                            data.createdAlbum = createdAlbum
                            if err
                                data.error = err
                                warn err, req
                            else
                                data.src = photo.thumb200
                            done data, photo
                    if album is "new"
                        if lastestAlbum
                            album = lastestAlbum
                            next()
                        else
                            Album.find(user: req.user._id)
                            .limit 1
                            .sort _id: 'desc'
                            .exec (err, foundAlbums) ->
                                if err
                                    data.error = err
                                    warn err, req
                                    done data
                                else
                                    album = (foundAlbums or [])[0]._id
                                    lastestAlbum = album
                                    next()
                    else
                        next()
        else
            res.render templateFolder + '/upload-photo', model

    router.delete '/photo', (req, res) ->
        photoId = req.user.photoId
        userModifications =
            photoId: null
            thumb: null
        for size in config.wornet.thumbSizes
            userModifications['thumb' + size] = null
        updateUser req, photoId: null, (err) ->
            PhotoPackage.delete photoId, 'published'
            res.json err: err

    router.delete '/media', (req, res) ->
        media = req.body.columns ['id', 'type', 'statusId', 'mediaId']
        media.type ||= 'image'
        me = req.user.id
        count = 1
        next = (err) ->
            if err
                warn err, req
            unless --count
                res.json()
        if media.statusId and media.mediaId
            count++
            findById Status, media.statusId, (err, status) ->
                if ! err and status and status.values(['at', 'author']).contains(me, equals)
                    key = media.type + 's'
                    if status[key]
                        status[key] = status[key].filter (val) ->
                            ! equals val._id, media.mediaId
                        count++
                        if status.isEmpty()
                            status.remove next
                        else
                            status.save next
                    else
                        next()
                next err
        if media.id and media.type is 'image'
            count++
            if equals req.user.photoId, media.id
                count++
                updateUser req, photoId: null, next
            where =
                _id: media.id
                user: me
                status: 'published'
            Photo.find where, (e, photos) ->
                photo = photos[0]
                whereAlbum =
                    album: photo.album
                    user: me
                    status: 'published'
                Photo.find whereAlbum, (e, photosAlbum) ->
                    # if there is only one photo in the album and it's the one we will delete
                    if photosAlbum and photosAlbum.length is 1 and equals photosAlbum[0]._id, photo._id
                        count++
                        Album.update
                            _id: photo.album
                            user: me
                        ,
                            lastEmpty: new Date
                        , (err) ->
                            next err
                parallelRemove [
                    Photo
                    where
                ], (err) ->
                    PhotoPackage.forget req, media.id
                    next e || err
        next()

    router.delete '/media/preview', (req, res) ->
        media = req.data.columns ['id', 'src']
        media.type ||= 'image'
        me = req.user.id
        count = 1
        next = (err, media) ->
            if err
                warn err, req
            unless --count
                res.json(media)

        if media.id and media.type is 'image'
            count++
            where =
                _id: media.id
                user: me
                status: 'uploaded'
            Photo.find where, (e) ->
                parallelRemove [
                    Photo
                    where
                ], (err) ->
                    PhotoPackage.forget req, media.id
                    next (e || err), media
        next()

    router.get '/chat', (req, res) ->
        ChatPackage.all req, (err, chat) ->
            if err
                warn err, req
                res.json()
            else
                res.json chat: chat

    router.get '/chat/list', (req, res) ->
        ChatPackage.list req, res

    router.delete '/chat', (req, res) ->
        ChatPackage.mask req, res, req.data.otherUser

    router.post '/first/:query', (req, res) ->
        query = req.params.query
        UserPackage.search 1, [req.user.id], query, (err, users) ->
            if err
                res.serverError err
            else
                if users.length
                    user = users[0]
                    res.redirect '/' + user.uniqueURLID
                else
                    res.notFound()

    searchesByIp = {}

    router.get '/search/:query', (req, res) ->
        res.setTimeLimit 0
        ip = req.connection.remoteAddress
        if searchesByIp[ip]
            searchesByIp[ip][0].publicJson()
            clearTimeout searchesByIp[ip][1]
        searchesByIp[ip] = [
            res
            delay 0.3.second, ->
                delete searchesByIp[ip]
                regexp = req.params.query.toBeginRegExp true
                friends = req.session.friends.filter (user) ->
                    regexp.test user.fullName
                limit = UserPackage.DEFAULT_SEARCH_LIMIT
                done = ->
                    res.json users: friends.unique('id').map (user) ->
                        user = objectToUser user
                        isAFriend = (req.session.friends || []).has id: user.id
                        isAFollower = (req.session.follower || []).contains user._id, equals
                        isAFollowing = (req.session.following || []).contains user._id, equals
                        extend user.publicInformations(),
                            isAFriend: isAFriend
                            askedForFriend: ! isAFriend and (req.session.friendAsks || {}).has hashedId: user.hashedId
                            isAFollower: isAFollower
                            isAFollowing: isAFollowing
                if friends.length >= 8
                    friends = friends.slice 0, limit
                    done()
                else
                    limit -= friends.length
                    exclude = [req.user.id]
                    exclude.merge friends.column 'id'
                    UserPackage.search exclude, regexp, limit, (err, users) ->
                        if err
                            res.serverError err
                        else
                            friends.merge users
                            done()
        ]

    router.get '/confirm/:hashedId/:token', (req, res) ->
        id = cesarRight req.params.hashedId
        if req.user._id and req.user._id isnt id
            auth.logout req, res
        User.findOneAndUpdate { _id: id, token: req.params.token }, { role: 'confirmed' }, {}, (err, user) ->
            if err or ! user
                req.flash 'loginErrors', s("Votre adresse n'a pas pu être confirmée")
                warn [user, err], req
            else if user
                auth.auth req, res, user
                req.flash 'profileSuccess', s("Votre adresse a bien été confirmée")
            res.redirect '/'

    router.delete '/', (req, res) ->
        findById User, req.user.id, (err, user) ->
            req.user = user
            req.tryPassword (ok) ->
                if ok
                    email = req.user.email
                    req.user.remove (err) ->
                        if err
                            res.serverError err
                        else
                            auth.logout req, res
                            req.flash 'loginSuccess', s("Votre compte a été correctement supprimé")
                            res.json goingTo: '/'
                            emailUnsubscribed email, (err, unsub) ->
                                unless unsub
                                    unsub = new Unsubscribe email: email
                                unsub.count++
                                unsub.save()
                                findOne Counter, name: 'unsubscribe', (err, counter) ->
                                    if counter
                                        counter.inc()

                else
                    res.serverError new PublicError s("Mot de passe incorrect")

    router.post '/chat/sound', (req, res) ->
        sound = req.data.chatSound
        id = req.user._id
        if id and sound
            User.findOneAndUpdate
                _id: id,
            ,
                chatSound: sound
            , (err, user) ->
                if err
                    res.serverError err
                else
                    req.user.chatSound = sound
                    res.json()
        else
            res.serverError new PublicError s("Vous n'avez choisi aucun son.")

    router.get '/checkURLID/:id', (req, res) ->
        id = req.params.id
        if id
            if id is req.user.uniqueURLID
                res.json err: "same"
            else
                User.count
                    uniqueURLID: id
                , (err, count) ->
                    warn err if err
                    res.json isAvailable: (if count then false else true)

    router.post '/certification', (req, res) ->
        if req.body and req.user and req.files and req.files.proof
            certification = req.body
            proof = req.files.proof
            certif = {
                user: req.user._id
                userType: certification.userType
                userFirstName: certification.firstName
                userLastName: certification.lastName
                userEmail: certification.email
                userTelephone: certification.telephone
                proof: name: proof.name
                status: "pending"
            }.with if certification.userType is "business" or certification.userType is "association"
                businessName: certification.entrepriseName
                message: certification.message


            if (['application/pdf', 'image/png', 'image/jpeg']).contains proof.type
                ext = if proof.type is 'application/pdf'
                    ".pdf"
                else
                    ".jpg"

                fileDirectory = __dirname + '/../../public/img/certification/'
                fileName = codeId() + time() + ext
                dst = fileDirectory + fileName
                certif.proof.src = '/img/certification/' + fileName
                fs.exists proof.path, (exists) ->
                    if exists
                        fs.readFile proof.path, (err, data) ->
                            warn err if err
                            if data
                                fs.writeFile dst, data, (err) ->
                                    warn err if err
                        CertificationAsk.create    certif, (err, certificationAsk) ->
                            warn err if err
                            email = config.wornet.admin.certifier
                            subject = s("Une nouvelle demande de certification est en attente.")
                            message = s("Un utilisateur vient de soumettre une demande de certification. Merci de la traiter.")
                            MailPackage.send email, subject, message
                            res.json()
                    else
                        res.serverError new PublicError s("Le justificatif n'existe pas.")
            else
                res.serverError new PublicError s("Le justificatif n'est pas dans un format accepté (png, jpeg, pdf)")
        else
            res.serverError new PublicError s("Veuillez renseigner les champs obligatoires")
        res.json()

    router.post '/following/list', (req, res) ->
        userHashedId = req.data.userHashedId
        offset = req.data.offset
        if userHashedId
            isAFriend = (req.session.friends || []).has id: cesarRight userHashedId
            isMe = if req.user
                userHashedId is req.user.hashedId
            else
                false
            isAPublicAccount req, userHashedId, true, (err, isAPublicAccount) ->
                if isAPublicAccount or isAFriend or isMe
                    where = follower: cesarRight userHashedId
                    .with if offset
                        _id: $lt: new ObjectId(offset).path
                    Follow.find where
                        .limit config.wornet.limits.followingsPageCount
                        .sort _id: 'desc'
                        .exec (err, follows) ->
                            warn err if err
                            followingIds = follows.column 'followed'
                            User.find
                                _id: $in: followingIds
                            , (err, followings) ->
                                warn err if err
                                sortedFollowings = []
                                for follow in follows
                                    for following in followings
                                        if equals(following._id, follow.followed)
                                            sortedFollowings.push following
                                res.json followings: sortedFollowings.map (user) ->
                                    userId = user._id
                                    user = user.publicInformations()
                                    for follow in follows
                                        if equals follow.followed, userId
                                            user.followId = follow._id
                                    user

                else
                    res.serverError new PublicError s("Vous ne pouvez pas voir les abonnements de ce compte.")
        else
            res.serverError new PublicError s("L'utilisateur est introuvable.")

    router.post '/follower/list', (req, res) ->
        userHashedId = req.data.userHashedId
        offset = req.data.offset
        if userHashedId
            isAFriend = (req.session.friends || []).has id: cesarRight userHashedId
            isMe = if req.user
                userHashedId is req.user.hashedId
            else
                false
            isAPublicAccount req, userHashedId, true, (err, isAPublicAccount) ->
                if isAPublicAccount or isAFriend or isMe
                    where = followed: cesarRight userHashedId
                    .with if offset
                        _id: $lt: new ObjectId(offset).path
                    Follow.find where
                        .limit config.wornet.limits.followersPageCount
                        .sort _id: 'desc'
                        .exec (err, follows) ->
                            warn err if err
                            followerIds = follows.column 'follower'
                            User.find
                                _id: $in: followerIds
                            , (err, followers) ->
                                warn err if err
                                sortedFollowers = []
                                for follow in follows
                                    for follower in followers
                                        if equals(follower._id, follow.follower)
                                            sortedFollowers.push follower
                                res.json followers: sortedFollowers.map (user) ->
                                    userId = user._id
                                    user = user.publicInformations()
                                    for follow in follows
                                        if equals follow.follower, userId
                                            user.followId = follow._id
                                    user

                else
                    res.serverError new PublicError s("Vous ne pouvez pas voir les abonnés de ce compte.")
        else
            res.serverError new PublicError s("L'utilisateur est introuvable.")

    router.post '/friend/list', (req, res) ->
        userHashedId = req.data.userHashedId
        offset = req.data.offset
        id = cesarRight userHashedId
        if userHashedId
            isAFriend = (req.session.friends || []).has id: id
            isMe = if req.user
                userHashedId is req.user.hashedId
            else
                false
            isAPublicAccount req, userHashedId, true, (err, isAPublicAccount) ->
                if isAPublicAccount or isAFriend or isMe
                    offsetObj = new ObjectId(offset).path
                    where = {
                        status: 'accepted'
                        $or: [
                            askedFrom: id

                        ,
                            askedTo: id
                        ]
                    }.with if offset
                        _id: $lt: offsetObj

                    Friend.find where
                        .limit config.wornet.limits.friendsPageCount
                        .sort _id: 'desc'
                        .exec (err, friendsObj) ->
                            warn err if err
                            userIds = []
                            for friend in friendsObj
                                if !equals friend._id, offsetObj
                                    if equals id, friend.askedFrom
                                        userIds.push friend.askedTo
                                    else
                                        userIds.push friend.askedFrom

                            User.find
                                _id: $in: userIds
                            , (err, friends) ->
                                warn err if err
                                sortedFriends = []
                                for friend in friendsObj
                                    for userFriend in friends
                                        if equals(friend.askedFrom, userFriend._id) or equals(friend.askedTo, userFriend._id)
                                            sortedFriends.push userFriend
                                res.json friends: sortedFriends.map (user) ->
                                    userId = user._id
                                    user = user.publicInformations()
                                    for friend in friendsObj
                                        if equals(userId, friend.askedFrom) or equals(userId, friend.askedTo)
                                            user.idFriend =  friend._id
                                    user
                else
                    res.serverError new PublicError s("Vous ne pouvez pas voir les amis de ce compte.")
        else
            res.serverError new PublicError s("L'utilisateur est introuvable.")

    router.get '/directory', (req, res) ->
        now = time()
        if now - directoryLastRetreive > 30.minutes
            directoryLastRetreive = now
            User.find
                accountConfidentiality: "public"
            , (err, users) ->
                warn err if err
                directoryPublicUsers = users
                res.render 'user/directory', publicUsers: users
        else
            res.render 'user/directory', publicUsers: directoryPublicUsers

    router.post '/share/list', (req, res) ->
        StatusPackage.getOriginalStatus req.data.status, (err, originalStatus) =>
            warn err if err
            if originalStatus
                if originalStatus.shares.length
                    Status.find
                        _id: $in: originalStatus.shares
                    , (err, shareList) ->
                        warn err if err
                        if shareList
                            userIds = []
                            sharers = {}
                            results = []
                            for share in shareList
                                if !sharers[share.author]
                                    sharers[share.author] = {user: share.author, nbShare: 1}
                                else
                                    sharers[share.author].nbShare++
                                userIds.push share.author
                            User.find
                                _id: $in: userIds
                            , (err, users) ->
                                warn err if err
                                for sharer of sharers
                                    for user in users
                                        if equals user._id, sharer
                                            userObj = user.publicInformations()
                                            userObj.nbShare = sharers[sharer].nbShare
                                            results.push userObj

                                res.json sharers: results
