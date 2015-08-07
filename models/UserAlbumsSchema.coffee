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
	UserAlbums.find user: user.id, (userAlbums) ->
		if user.photoAlbumId is albumId
			if userAlbums.lastFour and userAlbums.lastFour.length
				done()
			else
				userAlbums.lastFour = [user.photoAlbumId]
				userAlbums.save done
		else
			end = userAlbums.lastFour.filter (id) ->
				strval(id) isnt strval(albumId)
			.slice 1, 3
			userAlbums.lastFour = [albumId].concat end
			if user.photoAlbumId
				userAlbums.lastFour.unshift user.photoAlbumId
			userAlbums.save done

module.exports = userAlbumsSchema
