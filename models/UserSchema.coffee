'use strict'

userSchema = new Schema
	name:
		first:
			type: String
			validate: [regex('simple-text'), 'invalid first name']
			trim: true
		last:
			type: String
			validate: [regex('simple-text'), 'invalid last name']
			trim: true
	password:
		type: String
		required: true
	token:
		type: String
		default: ->
			generateSalt 50
	registerDate:
		type: Date
		default: Date.now
	role:
		type: String
		default: 'user'
		enum: ['user', 'admin']
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
	if name?
		split = name.split ' '
	else
		split = [null, null]
	@name.first = split[0]
	@name.last = split[1]
	return

userSchema.virtual('createdAt').get ->
	new Date parseInt(@_id.toString().slice(0,8), 16)*1000

userSchema.methods.encryptPassword = (plainText) ->
	crypto.createHmac('sha1', @token + @_id).update(plainText || @password).digest('hex')

userSchema.methods.passwordMatches = (plainText) ->
	@password is @encryptPassword(plainText)

userSchema.pre 'save', (next) ->
	if @isModified 'password'
		@password = @encryptPassword()
	next()


module.exports = userSchema
