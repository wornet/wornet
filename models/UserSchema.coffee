'use strict'

userSchema = new Schema
	name:
		first:
			type: String
			validate: [regex('simple-text'), 'invalid name']
			trim: true
		last:
			type: String
			validate: [regex('simple-text'), 'invalid name']
			trim: true
	registerDate: Date
	lastLoginDate: Date
	phone:
		type: String
		validate: [regex('phone'), 'invalid phone number']
		trim: true
	email:
		type: String
		required: true
		validate: [regex('email'), 'invalid e-mail address']
		trim: true
		set: strtolower
		unique: true

userSchema.virtual('name.full').get ->
	@name.first + ' ' + @name.last

userSchema.virtual('name.full').set (name) ->
	split = name.split ' '
	@name.first = split[0]
	@name.last = split[1]
	return


module.exports = userSchema
