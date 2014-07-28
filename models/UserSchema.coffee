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
	photoId:
		type: ObjectId
	token:
		type: String
		default: ->
			generateSalt 50
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
,
	toObject:
		virtuals: true
	toJSON:
		virtuals: true

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

userSchema.virtual('photoUpdateAt').get ->
	if @photoId?
		new Date parseInt(@photoId.toString().slice(0,8), 16)*1000
	else
		null

photoSrc = (prefix) ->
	'/img/' +(
		if @photoId?
			'photo/' + (prefix || '') + @photoId + '/' + @name.full.replace(/[^a-zA-Z0-9-]/g, '-')
		else
			'default-photo'
	) +
	'.jpg'

userSchema.virtual('photo').get ->
	photoSrc.call @

userSchema.virtual('thumb').get ->
	photoSrc.call @, '90x'

userSchema.methods.encryptPassword = (plainText) ->
	crypto.createHmac('sha1', @token + @_id).update(plainText || @password).digest('hex')

userSchema.methods.passwordMatches = (plainText) ->
	@password is @encryptPassword(plainText)

userSchema.pre 'save', (next) ->
	if @isModified 'password'
		@password = @encryptPassword()
	next()


module.exports = userSchema
