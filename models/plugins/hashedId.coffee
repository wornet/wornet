module.exports = (schema) ->
    schema.virtual('hashedId').get ->
        cesarLeft @id

    schema.statics.findByHashedId = ->
        if arguments.length
            arguments[0] = cesarRight arguments[0]
        @findById.apply @, arguments

