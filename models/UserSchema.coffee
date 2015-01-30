'use strict'

userSchema = BaseSchema.extend
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
		enum: [
			'user'
			'confirmed'
			'admin'
		]
	numberOfFriends:
		type: Number
		default: 0
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
		lowercase: true
		unique: true
	city:
		type: String
		trim: true
	birthCity:
		type: String
		trim: true
	job:
		type: String
		trim: true
	jobPlace:
		type: String
		trim: true
	maritalStatus:
		type: String
		enum: [
			null
			'celibate'
			'couple'
			'fiance'
			'married'
			'other'
		]
	loveInterest:
		type: String
		enum: [
			null
			'men'
			'women'
			'both'
		]
	biography:
		type: String
		validate: [
			(text) ->
				text.length <= config.wornet.limits.biographyLength
			'too long biography'
		]
		trim: true
	openedShutter:
		type: Boolean
		default: false
	newsletter:
		type: Boolean
		default: false
	noticeFriendAsk:
		type: Boolean
		default: false
	noticePublish:
		type: Boolean
		default: false
	noticeMessage:
		type: Boolean
		default: false
,
	toObject:
		virtuals: false
	toJSON:
		virtuals: true

userSchema.virtual('friendAsks')
	.get ->
		@_friendAsks ||= {}
	.set (friendAsks) ->
		for k, v of @_friendAsks
			delete @_friendAsks[k]
		extend @_friendAsks, friendAsks

userSchema.virtual('friends')
	.get ->
		@_friends
	.set (friends) ->
		@_friends = friends

getFullName = ->
	anonymous = 'Anonyme'
	if typeof @name isnt 'object'
		anonymous
	else
		f = empty @name.first
		l = empty @name.last
		if f and l
			anonymous
		else if f
			@name.last
		else if l
			@name.first
		else
			@name.first + ' ' + @name.last


for key in ['name.full', 'fullName']
	userSchema.virtual(key)
		.get getFullName
		.set (name) ->
			unless name is 'Anonyme'
				if name?
					split = name.split ' '
				else
					split = [null, null]
				@name.first = split[0]
				@name.last = split[1]
			return

userSchema.virtual('firstName').get ->
	@name.first
userSchema.virtual('lastName').get ->
	@name.last


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
	jpg(
		if @photoId?
			'photo/' + (prefix || '') + @photoId + '/' + @name.full.replace(/[^a-zA-Z0-9-]/g, '-')
		else
			'default-photo'
	)

userSchema.virtual('photo').get ->
	photoSrc.call @

userSchema.virtual('thumb').get ->
	photoSrc.call @, '90x'

for size in config.wornet.thumbSizes
	userSchema.virtual('thumb' + size).get ->
		photoSrc.call @, size + 'x'

userSchema.virtual('present').get ->
	NoticePackage.isPresent @id

preRegistration = null
userSchema.methods.preRegistered = ->
	if preRegistration is null
		preRegistration = require(__dirname + '/../core/system/preRegistration')()
	preRegistration.contains @email

userSchema.methods.publicInformations = (thumbSizes = null) ->
	values = ['hashedId', 'present']
	if thumbSizes is null
		thumbSizes = [50, 90, 200]
	else unless thumbSizes instanceof Array
		thumbSizes = Array.prototype.slice.call arguments
	thumbSizes.each ->
		values.push 'thumb' + @
	informations = @columns values
	informations.name = @name.toObject()
	informations.name.full = @name.full
	informations

userSchema.methods.encryptPassword = (plainText) ->
	sha1 plainText || @password, @token + @_id

userSchema.methods.passwordMatches = (plainText) ->
	@password is @encryptPassword(plainText)

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
		user = @
		ids = []
		friendAskIds = []
		friendAskFromIds = []
		friendAskDates = []
		pending = 2
		next = ->
			User.find
				_id: $in: ids
			, (err, users) ->
				if err
					done err, {}, {}
				else
					friendIds = []
					friends = []
					friendAsks = {}
					users.forEach (user) ->
						id = strval user.id
						if friendAskIds.contains id
							askedFrom = friendAskFromIds.contains id
							user = user.publicInformations()
							user.askedFrom = askedFrom
							user.askedTo = !askedFrom
							friendAsks[friendAskDates[id]] = user
						else
							friends.push user
							friendIds.push id
					user.numberOfFriends = friends.length
					user.friendIds = friendIds
					user.friends = friends
					user.friendAsks = friendAsks
					done null, friends, friendAsks
		Friend.find
				askedFrom: @_id
				status: $in: ['waiting', 'accepted']
			.limit 10
			.exec (err, friends) ->
				unless err
					for friend in friends
						ids.push friend.askedTo
						if friend.isWaiting()
							askedTo = strval friend.askedTo
							friendAskIds.push askedTo
							friendAskFromIds.push askedTo
							friendAskDates[askedTo] = friend.id
				unless --pending
					next()
		Friend.find
				askedTo: @_id
				status: $in: ['waiting', 'accepted']
			.limit 10
			.exec (err, friends) ->
				unless err
					for friend in friends
						ids.push friend.askedFrom
						if friend.isWaiting()
							friendAskIds.push strval friend.askedFrom
							friendAskDates[friend.askedFrom] = friend.id
					user.friendAskIds = friendAskIds
					user.friendAskDates = friendAskDates
				unless --pending
					next()

userSchema.pre 'save', (next) ->
	if @isModified 'password'
		@password = @encryptPassword()
	next()

userSchema.pre 'remove', (next) ->
	parallelRemove [
		Friend
		$or: [
			askedFrom: @id
		,
			askedTo: @id
		]
	], [
		Status
		$or: [
			author: @id
		,
			at: @id
		]
	], [
		Comment
		author: @id
	], [
		Album
		user: @id
	], [
		Event
		user: @id
	], [
		Photo
		user: @id
	], [
		Link
		user: @id
	], [
		Video
		user: @id
	], [
		Message
		author: @id
	], [
		MessageRecipient
		recipient: @id
	], [
		ResetPassword
		user: @id
	], next


module.exports = userSchema
