'use strict'

videoSchema = BaseSchema.extend
	user:
		type: ObjectId
		ref: 'UserSchema'
	url:
		type: String
		trim: true
	album:
		type: ObjectId
		ref: 'AlbumSchema'

module.exports = videoSchema
