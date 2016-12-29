'use strict'

app.onready ->
    User.find
        $or: [
            photoUploadAlbumId:
                $exists: false
        ,
            photoUploadAlbumId: null
        ]
    , (err, users) ->
        warn err if err
        if users
            each users, ->
                user = @
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
                            console['log'] "Album Téléchargement créé pour " + user.fullName
