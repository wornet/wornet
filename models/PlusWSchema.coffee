'use strict'

plusWSchema = BaseSchema.extend
	user:
		type: ObjectId
		ref: 'UserSchema'
		required: true
	status:
		type: ObjectId
		ref: 'StatusSchema'
		required: true

module.exports = plusWSchema
