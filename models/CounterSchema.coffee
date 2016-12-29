'use strict'

counterSchema = new Schema
    name:
        type: String
        required: true
        index: true
    count:
        type: Number
        default: 0

counterSchema.methods.inc = (i = 1, done) ->
    if 'function' is typeof i
        done = i
        i = 1
    @count += i
    @save done || ->

module.exports = counterSchema
