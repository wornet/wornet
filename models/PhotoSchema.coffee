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
	status:
		type: String
		default: 'uploaded'
		enum: [
			'uploaded'
			'published'
		]

photoSrc = (prefix) ->
	jpg(
		if @_id?
			'photo/' + (prefix || '') + @_id
		else
			'default-photo'
	)

photoSchema.virtual('photo').get ->
	photoSrc.call @

photoSchema.virtual('thumb').get ->
	photoSrc.call @, '90x'

for size in config.wornet.thumbSizes
	photoSchema.virtual('thumb' + size).get ->
		photoSrc.call @, size + 'x'

photoSchema.pre 'remove', (next) ->
	photoDirectory = __dirname + '/../public/img/photo/'
	fs.unlink photoDirectory + @id + '.jpg'
	for size in config.wornet.thumbSizes
		fs.unlink photoDirectory + size + 'x' + @id + '.jpg'
	next()


module.exports = photoSchema
