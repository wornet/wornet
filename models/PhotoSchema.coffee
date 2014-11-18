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

photoSchema.virtual('thumb90').get ->
	photoSrc.call @, '90x'

photoSchema.virtual('thumb50').get ->
	photoSrc.call @, '50x'

photoSchema.virtual('thumb200').get ->
	photoSrc.call @, '200x'

photoSchema.methods.getAlbum = (done) ->
	Album.findById @album, done

module.exports = photoSchema
