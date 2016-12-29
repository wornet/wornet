'use strict'

messageSchema = BaseSchema.extend
    author:
        type: ObjectId
        ref: 'UserSchema'
    content:
        type: String
        trim: true
        required: true
    maskedFor:
        type: Array

module.exports = messageSchema
