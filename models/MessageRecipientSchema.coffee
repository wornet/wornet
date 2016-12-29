'use strict'

messageRecipientSchema = BaseSchema.extend
    message:
        type: ObjectId
        ref: 'MessageSchema'
    recipient:
        type: ObjectId
        ref: 'UserSchema'
    status: readOrUnread.type

readOrUnread.virtuals messageRecipientSchema

messageRecipientSchema.pre 'remove', (next) ->
    parallelRemove [
        Message
        id: @message
    ], next

module.exports = messageRecipientSchema
