'use strict'

unsubscribeSchema = new Schema
    email:
        type: String
        required: true
    count:
        type: Number
        default: 0

module.exports = unsubscribeSchema
