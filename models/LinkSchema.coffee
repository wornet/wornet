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
	referencedStatus:
		type: ObjectId
		ref: 'StatusSchema'
	metaData:
		title:
			type: String
			trim:true
		description:
			type: String
			trim:true
		image:
			type: String
			trim:true
		author:
			type: String
			trim:true
		link:
			type: String
			trim:true

module.exports = linkSchema
