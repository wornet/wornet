'use strict'

userSchema = new Schema
	name:
		first:
			type: String
			validate: [/^[^><&\n\r]+$/, 'invalid name']
			trim: true
		last:
			type: String
			validate: [/^[^><&\n\r]+$/, 'invalid name']
			trim: true
	registerDate: Date
	lastLoginDate: Date
	phone:
		type: String
		validate: [/^(\+\d+(\s|-))?0\d(\s|-)?(\d{2}(\s|-)?){4}$/, 'invalid phone number']
		trim: true
	email:
		type: String
		required: true
		validate: [/^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.+_-]+\.[a-zA-Z]{2,}$/, 'invalid e-mail address']
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
