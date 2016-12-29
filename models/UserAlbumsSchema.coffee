'use strict'

userAlbumsSchema = BaseSchema.extend
    user:
        type: ObjectId
        ref: 'UserSchema'
        required: true
    lastFour: [
        type: ObjectId
        ref: 'AlbumSchema'
    ]

# UserAlbums.touchAlbum user, album.id, ->
userAlbumsSchema.statics.touchAlbum = (user, albumId, done) ->
    UserAlbums.findOne user: user.id, (err, userAlbums) ->
        toCreate = false
        if !userAlbums
            userAlbums = {}
            userAlbums.lastFour = []
            userAlbums.user = user._id
            toCreate = true
        if strval(user.photoAlbumId) is strval(albumId)
            if userAlbums.lastFour and userAlbums.lastFour.length and userAlbums.lastFour.contains strval(albumId)
                done()
            else
                if userAlbums.lastFour
                    userAlbums.lastFour.unshift user.photoAlbumId
                else
                    userAlbums.lastFour = [user.photoAlbumId]
                unless toCreate
                    userAlbums.save done
                else
                    UserAlbums.create userAlbums, done
        else
            end = userAlbums.lastFour.filter (id) ->
                strval(id) isnt strval(albumId)

            if end.contains user.photoAlbumId, equals
                end = end.slice 1, 3


            userAlbums.lastFour = [albumId].concat end
            if user.photoAlbumId and !userAlbums.lastFour.contains user.photoAlbumId, equals
                userAlbums.lastFour.unshift user.photoAlbumId

            limit = if userAlbums.lastFour.contains user.photoAlbumId, equals
                4
            else
                3
            userAlbums.lastFour = userAlbums.lastFour.slice 0, limit
            unless toCreate
                userAlbums.save done
            else
                UserAlbums.create userAlbums, done

userAlbumsSchema.statics.removeAlbum = (user, albumId, done) ->
    UserAlbums.findOne user: user.id, (err, userAlbums) ->
        if !err and userAlbums
            if !userAlbums.lastFour.contains albumId
                done()
            else
                #we remove the albumId from the lastFour
                userAlbums.lastFour.splice userAlbums.lastFour.indexOf(albumId), 1

                Album.find
                    user: user._id
                    name: $ne: photoDefaultName()
                .select('_id')
                .sort(lastAdd:'desc')
                .exec (err, albumIdsList) ->
                    if err
                        done err
                    else
                        albumIds = albumIdsList.column '_id'
                        Photo.aggregate [
                            $match:
                                status: "published"
                                album: $in: albumIds
                        ,
                            $group:
                                _id: "$album"
                                count: $sum: 1
                        ], (err, notEmptyAlbums) ->
                            # #hack for let coffescript declare the variables before the label
                            # a = null
                            # `firstloop: //`
                            # for id in albumIdsList
                            #     for data in notEmptyAlbums
                            #         # We have found the first album which is in all ordered albums and in the not empty albums
                            #         if strval(data._id) is strval(id)
                            #             userAlbums.lastFour.push id
                            #             userAlbums.save()
                            #             `break firstloop`
                            #             return
                            # done()
                            do ->
                                for id in albumIds
                                    for data in notEmptyAlbums
                                        # We have found the first album which is in all ordered albums and in the not empty albums
                                        if strval(data._id) is strval(id)
                                            unless userAlbums.lastFour.contains id
                                                userAlbums.lastFour.push id
                                                return
                            userAlbums.save()
                            done()


module.exports = userAlbumsSchema
