'use strict'

noticeSchema = OwnedSchema.extend
	content:
		type: String
		required: true
		trim: true

module.exports = noticeSchema
