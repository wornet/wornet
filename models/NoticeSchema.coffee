'use strict'

noticeSchema = OwnedSchema.extend
	content:
		type: String
		required: true
		trim: true
	status: readOrUnread.type

noticeSchema.virtual('isUnread').get ->
	@status is readOrUnread.unread

noticeSchema.virtual('isRead').get ->
	! @isUnread

module.exports = noticeSchema
