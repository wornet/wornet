'use strict'

followSchema = BaseSchema.extend
    follower:
        type: ObjectId
        ref: 'UserSchema'
        required: true
    followed:
        type: ObjectId
        ref: 'UserSchema'
        required: true

module.exports = followSchema
