'use strict'

photoSchema = BaseSchema.extend
	user:
		type: ObjectId
		ref: 'UserSchema'
	name:
		type: String
		trim: true
	album:
		type: ObjectId
		ref: 'AlbumSchema'

photoSrc = (prefix) ->
	'/img/' + (
		if @_id?
			'photo/' + (prefix || '') + @_id
		else
			'default-photo'
	) +
	'.jpg'

photoSchema.virtual('photo').get ->
	photoSrc.call @

photoSchema.virtual('thumb').get ->
	photoSrc.call @, '90x'

for size in config.wornet.thumbSizes
	photoSchema.virtual('thumb' + size).get ->
		photoSrc.call @, size + 'x'

photoSchema.methods.getAlbum = (done) ->
	Album.findById @album, done

photoSchema.pre 'save', (next) ->
	preview = {}
	savePreview = ->
		if preview.album and preview.photos
			preview.album.preview = preview.photos
			preview.album.save()
	Photo.find album: @album
		.sort '-id'
		.limit 4
		.exec (err, photos) ->
			unless err
				preview.photos = photos.column '_id'
				savePreview()
	@getAlbum (err, album) ->
		unless err
			preview.album = album
			savePreview()
	next()

module.exports = photoSchema
