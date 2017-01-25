'use strict'

appSchema = OwnedSchema.extend
    description:
        type: String
        required: true
        trim: true
    url:
        type: String
        required: true
        trim: true
    secretKey:
        type: String
        required: true
        default: ->
            generateSalt 40

appSchema.virtual('publicKey').get ->
    @id

appSchema.virtual('launchUrl').get ->
    '/app/' + @id + '/' + encodeURIComponent @name

appSchema.methods.publicInformations = ->
    @columns ['name', 'description', 'url', 'publicKey']

appSchema.statics.findByPublicKey = ->
    args = Array::slice.call arguments
    args.unshift @
    findById args

module.exports = appSchema
