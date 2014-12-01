'use strict'

linkSchema = BaseSchema.extend
	user:
		type: ObjectId
		ref: 'UserSchema'
	https:
		type: String
		trim: true
	name:
		type: String
		trim: true
	url:
		type: String
		trim: true
	album:
		type: ObjectId
		ref: 'AlbumSchema'

module.exports = linkSchema
