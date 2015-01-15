'use strict'

linkSchema = OwnedSchema.extend
	https:
		type: String
		trim: true
	url:
		type: String
		trim: true
	album:
		type: ObjectId
		ref: 'AlbumSchema'

module.exports = linkSchema
