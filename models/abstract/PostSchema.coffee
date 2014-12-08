###
@abstract
@class
###

PostSchema = ->
	throw new Error "BaseSchema is an abstract class and cannot be instancied"

###
@abstract
@class
###

PostSchema.extend = (columns, options) ->
	extend columns,
		date:
			type: Date
			default: Date.now
			required: true
		status:
			type: String
			default: 'active'
			enum: [
				'active'
				'blocked'
			]
		author:
			type: ObjectId
			ref: 'UserSchema'
			required: true
		content:
			type: String
			trim: true
		images: [
			name:
				type: String
				trim: true
			src:
				type: String
				trim: true
		]
		videos: [
			href:
				type: String
				trim: true
		]
		links: [
			href:
				type: String
				trim: true
			https: Boolean
		]

	BaseSchema.extend columns, options

module.exports = PostSchema
