'use strict'

noticeSchema = OwnedSchema.extend
	content:
		type: String
		required: true
		trim: true
	status: readOrUnread.type
	type:
		type: String
	launcher:
		type: ObjectId
		ref: 'UserSchema'
	attachedStatus:
		type: ObjectId
		ref: 'StatusSchema'
	place:
		type: ObjectId
		ref: 'UserSchema'
	originService:
		type: 'String'
		enum: [
			'espacePersonnel'
			'espaceProfessionnel'
			'dailyCapture'
			'bouger'
		]
		default: 'espacePersonnel'

noticeSchema.virtual('isUnread').get ->
	@status is readOrUnread.unread

noticeSchema.virtual('isRead').get ->
	! @isUnread

module.exports = noticeSchema
