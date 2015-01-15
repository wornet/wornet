'use strict'

invitationSchema = BaseSchema.extend
	host:
		type: ObjectId
		ref: 'UserSchema'
	status:
		type: String
		enum: [
			'invited'
			'registered'
		]
		default: 'invited'
	sended:
		type: Date
		default: null
	email:
		type: String
		required: true
		validate: [
			regex('email')
			'invalid e-mail address'
		]
		trim: true
		lowercase: true
		unique: true

module.exports = invitationSchema
