'use strict'

readOrUnread =
    read: 'read'
    unread: 'unread'
    virtuals: (schema, prefix) ->
        status.forEach (st) ->
            if prefix
                st = prefix + ucfirst st
            schema.virtual(st).get ->
                @status is st
    setToRead: (done) ->
        @status = readOrUnread.read
        @save done
    setToUnread: (done) ->
        @status = readOrUnread.unread
        @save done

status = [
    readOrUnread.unread
    readOrUnread.read
]

readOrUnread.type =
    type: String
    enum: status
    default: readOrUnread.unread

module.exports = readOrUnread
