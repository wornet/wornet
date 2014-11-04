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

userSchema.virtual('name.full').get getFullName
userSchema.virtual('fullName').get getFullName
userSchema.virtual('firstName').get ->
	@name.first
userSchema.virtual('lastName').get ->
	@name.last

userSchema.virtual('name.full').set (name) ->
	unless name is 'Anonyme'
		if name?
			split = name.split ' '
		else
			split = [null, null]
		@name.first = split[0]
		@name.last = split[1]
	return


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

userSchema.methods.publicInformations = (thumbSize = 50) ->
	informations = @values ['hashedId', 'thumb' + thumbSize], true
	informations.name = @name.toObject()
	informations.name.full = @name.full
	informations

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

userSchema.methods.getFriendIds = (done) ->
	if @friendIds?
		done null, @friendIds
	else
		user = @
		ids = []
		Friend.find
				askedFrom: @_id
				status: 'accepted'
			# .where('status').in ['waiting', 'accepted']
			.limit 10
			.exec (err, friends) ->
				if err
					done err
				else
					done null, user.friendIds

userSchema.methods.getFriendAndAskIds = (done) ->
	user = @
	if user.friendIds? and user.friendAskIds? and uer.friendAskDates?
		done null, user.friendIds, user.friendAskIds, uer.friendAskDates
	userSchema.methods.getFriendIds (err, ids) ->
		if err
			done err
		else if user.friendAskIds? and user.friendAskDates?
			user.friendAskIds.each ->
				ids.push @
			done null, ids, user.friendAskIds, user.friendAskDates
		else
			friendAskIds = []
			friendAskDates = []
			Friend.find
					askedTo: @_id
				.where('status').in ['waiting', 'accepted']
				.limit 10
				.exec (err, friends) ->
					if err
						done err
					else
						for friend in friends
							if friend.waiting
								friendAskIds.push strval friend.askedFrom
								friendAskDates[friend.askedFrom] = friend.id
							else
								ids.push friend.askedFrom
						user.friendIds = ids
						user.friendAskIds = friendAskIds
						user.friendAskDates = friendAskDates
						done null, ids, friendAskIds, friendAskDates

userSchema.methods.getFriends = (done) ->
	if @friends? and @friendAsks?
		done null, @friends, @friendAsks
	else
		user = @
		ids = []
		friendAskIds = []
		friendAskDates = []
		pending = 2
		next = ->
			User.find()
				.where('_id').in ids #.slice 0, config.wornet.limits.friendsOnProfile
				.exec (err, users) ->
					if err
						done err, {}, {}
					else
						friendIds = []
						friends = []
						friendAsks = {}
						users.forEach (user) ->
							id = strval user.id
							if friendAskIds.indexOf(id) is -1
								friends.push user
								friendIds.push id
							else
								friendAsks[friendAskDates[id]] = user
						user.numberOfFriends = friends.length
						user.friendIds = friendIds
						user.friends = friends
						user.friendAsks = friendAsks
						done null, friends, friendAsks
		Friend.find
				askedFrom: @_id
				status: 'accepted'
			# .where('status').in ['waiting', 'accepted']
			.limit 10
			.exec (err, friends) ->
				unless err
					for friend in friends
						ids.push friend.askedTo
						# if friend.waiting
						# 	friendAskIds.push strval friend.askedTo
						# 	friendAskDates[friend.askedTo] = friend.id
				unless --pending
					next()
		Friend.find
				askedTo: @_id
			.where('status').in ['waiting', 'accepted']
			.limit 10
			.exec (err, friends) ->
				unless err
					for friend in friends
						ids.push friend.askedFrom
						if friend.waiting
							friendAskIds.push strval friend.askedFrom
							friendAskDates[friend.askedFrom] = friend.id
					user.friendAskIds = friendAskIds
					user.friendAskDates = friendAskDates
				unless --pending
					next()


module.exports = userSchema
