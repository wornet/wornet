'use strict'

resetPasswordSchema = BaseSchema.extend
	user:
		type: ObjectId
		ref: 'UserSchema'
		required: true
	token:
		type: String
		trim: true
		default: ->
			generateSalt 50

module.exports = resetPasswordSchema
