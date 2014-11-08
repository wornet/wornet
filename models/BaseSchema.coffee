###
@abstract
@class
###

BaseSchema = ->
	throw new Error "BaseSchema is an abstract class and cannot be instancied"

###
@abstract
@class
###

BaseSchema.extend = (columns, options) ->
	schema = new Schema columns, options

	schema.plugin require './plugins/createdAt'
	schema.plugin require './plugins/hashedId'
	schema

module.exports = BaseSchema
