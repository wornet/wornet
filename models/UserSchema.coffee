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
	sex:
		type: String
		enum: [
			'default'
			'man'
			'woman'
		]
		required: true
		default: 'default'
	password:
		type: String
		required: true
	photoId:
		type: ObjectId
		ref: 'PhotoSchema'
	photoAlbumId:
		type: ObjectId
		ref: 'AlbumSchema'
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
	bestFriends: [
		type: ObjectId
		ref: 'UserSchema'
	]
	numberOfFriends:
		type: Number
		default: 0
	lastActivity: Date
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
	maskBirthDate:
		type: Boolean
		default: false
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
				text is null or text.length <= config.wornet.limits.biographyLength
			'too long biography'
		]
		trim: true
	openedShutter:
		type: Boolean
		default: false
	firstStepsDisabled:
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
	points:
		type: Number
	chatSound:
		type: Number
		default: 1
,
	toObject:
		virtuals: false
	toJSON:
		virtuals: true

userSchema.virtual('friendAsks')
	.get ->
		@_friendAsks ||= {}
	.set (friendAsks) ->
		for k, v of @friendAsks
			unless friendAsks[k]
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
			@name.last.ucFirst()
		else if l
			@name.first.ucFirst()
		else
			@name.first.ucFirst() + ' ' + @name.last.ucFirst()


for key in ['name.full', 'fullName']
	userSchema.virtual(key)
		.get getFullName
		# .set (name) ->
		# 	unless name is 'Anonyme'
		# 		if name?
		# 			split = name.split ' '
		# 		else
		# 			split = [null, null]
		# 		@name.first = split[0]
		# 		@name.last = split[1]
		# 	return

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
	if @birthDate instanceof Date and @birthDate.isValid() and !@maskBirthDate
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

config.wornet.thumbSizes.each ->
	size = @
	userSchema.virtual('thumb' + size).get ->
		photoSrc.call @, size + 'x'

userSchema.virtual('present').get ->
	NoticePackage.isPresent @id

preRegistration = null

extend userSchema.methods,

	preRegistered: ->
		if preRegistration is null
			preRegistration = require(__dirname + '/../core/system/preRegistration')()
		preRegistration.contains @email

	publicInformations: (thumbSizes = null) ->
		values = [
			'hashedId'
			'present'
			'chatSound'
			'sex'
			'photoAlbumId'
		]
		if thumbSizes is null
			thumbSizes = [50, 90, 200]
		else unless thumbSizes instanceof Array
			thumbSizes = Array.prototype.slice.call arguments
		thumbSizes.each ->
			values.push 'thumb' + @
		informations = @columns values
		informations.name = @name.toObject()
		informations.name.full = @name.full
		informations.points = @points || 0
		informations

	sha1Fallback: (plainText) ->
		sha1 plainText, @token + @_id

	isABestFriend: (hashedId) ->
		(@bestFriends || []).contains hashedId

	saveAsABestFriend: (hashedId, next) ->
		if @isABestFriend hashedId
			next()
		else
			user = @
			done = (err, friends) ->
				if ! err and friends.has(hashedId: hashedId)
					(user.bestFriends ||= []).push hashedId
					updateUser user, bestFriends: user.bestFriends, next
				else
					next err || new PublicError s("{username} n'est pas dans votre liste d'amis actuellement.", user)
			@getFriends done, true

	saveAsANormalFriend: (hashedId, next) ->
		@bestFriends = (@bestFriends || []).filter (id) ->
			! equals id, hashedId
		updateUser @, bestFriends: @bestFriends, next

	encryptPassword: (plainText, done) ->
		if 'function' is typeof plainText
			done = plainText
			plainText = @password
		done = done.bind @
		fallback = @bind ->
			done @sha1Fallback plainText
		try
			bcrypt = require 'bcrypt-nodejs'
			bcrypt.hash plainText, config.wornet.security.saltWorkFactor, (err, hash) ->
				if err
					if err
						warn err
					fallback()
				else
					done hash
		catch e
			unless e.code is 'MODULE_NOT_FOUND' and config.env.development
				warn e
			fallback()

	passwordMatches: (plainText, done) ->
		if @password is @sha1Fallback plainText
			done true
		else
			try
				bcrypt = require 'bcrypt-nodejs'
				bcrypt.compare plainText, @password, (err, isMatch) ->
					if err
						warn err
					done isMatch
			catch e
				unless e.code is 'MODULE_NOT_FOUND' and config.env.development
					warn e
				done false

	countUnreadNotifications: (done) ->
		Notice.count
			status: $ne: 'read'
			user: @id
		, (err, count) ->
			if err
				warn err
			done count

	askForFriend: (askedTo, done) ->
		askedFrom = @id
		if askedFrom is askedTo
			done
				err: new PublicError s("Vous vous aimez, et vous avez bien raison. Mais nous ne pouvons pas ajouter votre propre profil à vos amis.")
				friend: null
		else
			data =
				askedFrom: askedFrom
				askedTo: askedTo
			Friend
				.findOne $or: [
					askedFrom: askedTo
					askedTo: askedFrom
					data
				]
				.exec (err, friend) ->
					if err
						warn err
					exists = false
					next = ->
						if typeof done is 'function'
							done
								err: err
								friend: friend
								exists: exists
					if friend
						exists = equals askedTo, friend.askedFrom
						unless exists
							err = new PublicError s("Une demande est déjà en attente.")
						next()
						# if config.wornet.lockFriendAsk.contains friend.status
						# 	err = new PublicError s("Une demande est déjà en attente.")
						# 	next()
						# else
						# 	friend.status = 'waiting'
						# 	friend.save next
					else unless err
						friend = new Friend data
						friend.save next
					else
						next()

	getFriendsIds: (done, forceReload = false, returnIds = true) ->
		@getFriends done, forceReload, returnIds

	getFriendsIdsFromDataBase: (done, forceReload = true, returnIds = true) ->
		@getFriends done, forceReload, returnIds

	getFriends: (done, forceReload = false, returnIds = false) ->
		if ! forceReload and @friends? and @friendAsks?
			if returnIds
				done null, @friends.column('_id'), @friendAsks.column('_id')
			else
				done null, @friends, @friendAsks
		else
			user = @
			ids = []
			friendAskIds = []
			friendAskFromIds = []
			friendAskDates = []
			pending = 2
			next = ->
				unless --pending
					if returnIds
						friendsIds = ids.filter (id) ->
							! friendAskIds.contains id
						done null, friendsIds, friendAskIds
					else
						User.find
							_id: $in: ids
						, (err, users) ->
							if err
								done err, [], {}
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
				.exec (err, friends) ->
					unless err
						for friend in friends
							ids.push friend.askedTo
							if friend.isWaiting()
								askedTo = strval friend.askedTo
								friendAskIds.push askedTo
								friendAskFromIds.push askedTo
								friendAskDates[askedTo] = friend.id
					next()
			Friend.find
					askedTo: @_id
					status: $in: ['waiting', 'accepted']
				.exec (err, friends) ->
					unless err
						for friend in friends
							ids.push friend.askedFrom
							if friend.isWaiting()
								friendAskIds.push strval friend.askedFrom
								friendAskDates[friend.askedFrom] = friend.id
						user.friendAskIds = friendAskIds
						user.friendAskDates = friendAskDates
					next()

userSchema.pre 'save', (next) ->
	if @isModified 'password'
		@encryptPassword (hash) ->
			@password = hash
			next()
	else
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
	], [
		App
		user: @id
	], next

userSchema.plugin require 'mongoose-simple-random'

module.exports = userSchema
