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
			if userAlbums.lastFour and userAlbums.lastFour.length
				done()
			else
				userAlbums.lastFour = [user.photoAlbumId]
				unless toCreate
					userAlbums.save done
				else
					UserAlbums.create userAlbums, done
		else
			end = userAlbums.lastFour.filter (id) ->
				strval(id) isnt strval(albumId)
			.slice 1, 3
			userAlbums.lastFour = [albumId].concat end
			if user.photoAlbumId
				userAlbums.lastFour.unshift user.photoAlbumId
			unless toCreate
				userAlbums.save done
			else
				UserAlbums.create userAlbums, done

module.exports = userAlbumsSchema
