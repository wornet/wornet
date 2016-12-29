'use strict'

###
@abstract
@class
###

OwnedSchema = ->
    throw new Error "OwnedSchema is an abstract class and cannot be instancied"

###
@abstract
@class
###

OwnedSchema.extend = (columns, options) ->
    extend columns,
        user:
            type: ObjectId
            ref: 'UserSchema'
    columns.name ||= {}
    columns.name.type ||= String
    if typeof(columns.name.trim) is 'undefined'
        columns.name.trim = true

    BaseSchema.extend columns, options

module.exports = OwnedSchema
