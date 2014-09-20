'use strict'

userSchema = new Schema
	name:
		first:
			type: String
			validate: [
				regex('simple-text')
				'invalid first name'
			]
			trim: true
			required: true
		last:
			type: String
			validate: [
				regex('simple-text')
				'invalid last name'
			]
			trim: true
			required: true
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
	birthDate:
		type: Date
		validate: [
			(date) ->
				if date.isValid()
					age = date.age()
					age <= config.wornet.limits.userMaxAge and age >= config.wornet.limits.userMinAge
				else
					false
			'invalid birth date'
		]
		required: true
	phone:
		type: String
		validate: [
			regex('phone')
			'invalid phone number'
		]
		trim: true
	email:
		type: String
		required: true
		validate: [
			regex('email')
			'invalid e-mail address'
		]
		trim: true
		set: strtolower
		unique: true
,
	toObject:
		virtuals: true
	toJSON:
		virtuals: true

userSchema.virtual('name.full').get ->
	f = empty @name.first
	l = empty @name.last
	if f and l
		'Anonyme'
	else if f
		@name.last
	else if l
		@name.first
	else 
		@name.first + ' ' + @name.last

userSchema.virtual('name.full').set (name) ->
	unless name is 'Anonyme'
		if name?
			split = name.split ' '
		else
			split = [null, null]
		@name.first = split[0]
		@name.last = split[1]
	return

userSchema.virtual('createdAt').get ->
	Date.fromId @_id

userSchema.virtual('photoUpdateAt').get ->
	if @photoId?
		Date.fromId @photoId
	else
		null

userSchema.virtual('age').get ->
	if @birthDate instanceof Date and @birthDate.isValid()
		@birthDate.age()
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

userSchema.virtual('thumb50').get ->
	photoSrc.call @, '50x'

userSchema.virtual('thumb90').get ->
	photoSrc.call @, '90x'

userSchema.virtual('thumb200').get ->
	photoSrc.call @, '200x'

userSchema.methods.encryptPassword = (plainText) ->
	sha1 plainText || @password, @token + @_id

userSchema.methods.passwordMatches = (plainText) ->
	@password is @encryptPassword(plainText)

userSchema.pre 'save', (next) ->
	if @isModified 'password'
		@password = @encryptPassword()
	next()

userSchema.methods.aksForFriend = (askedTo, done) ->
	askedFrom = @id
	if askedFrom is askedTo
		done
			err: 'self-ask'
			friend: null
	else
		data =
			askedFrom: askedFrom
			askedTo: askedTo
		Friend
			.findOne data
			.exec (err, friend) ->
				unless err or friend
					friend = new Friend data
					friend.save()
				if typeof done is 'function'
					done
						err: err
						friend: friend

userSchema.methods.getFriends = (done) ->
	if @friends? and @friendAsks?
		done null, @friends, @friendAsks
	else
		ids = []
		friendAsksIds = []
		friendAskDates = []
		pending = 2
		next = ->
			User.find()
				.where('_id').in ids #.slice 0, config.wornet.limits.friendsOnProfile
				.exec (err, users) ->
					if err
						done err, {}, {}
					else
						friends = []
						friendAsks = {}
						users.forEach (user) ->
							id = strval user.id
							if friendAsksIds.indexOf(id) is -1
								friends.push user
							else
								friendAsks[friendAskDates[id]] = user
						done null, friends, friendAsks
		Friend.find askedFrom: @_id
			.where('status').in ['waiting', 'accepted']
			.limit 10
			.exec (err, friends) ->
				unless err
					for friend in friends
						ids.push friend.askedTo
				unless --pending
					next()
		Friend.find askedTo: @_id
			.where('status').in ['waiting', 'accepted']
			.limit 10
			.exec (err, friends) ->
				unless err
					for friend in friends
						ids.push friend.askedFrom
						if friend.waiting
							friendAsksIds.push strval friend.askedFrom
							friendAskDates[friend.askedFrom] = friend.id
				unless --pending
					next()


module.exports = userSchema
