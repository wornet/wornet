'use strict'

photoSchema = new Schema
	user:
		type: ObjectId
		ref: 'UserSchema'
	name:
		type: String
		trim: true
	album:
		type: Number
		default: 0

photoSrc = (prefix) ->
	'/img/' +(
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

photoSchema.virtual('createdAt').get ->
	new Date parseInt(@_id.toString().slice(0,8), 16)*1000

module.exports = photoSchema
