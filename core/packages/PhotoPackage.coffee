'use strict'


albumRefreshes = {}

prefix = 'p:'

setCookie = (req, photoId, value, unset = false) ->
	maxAge = 1.day
	if unset
		maxAge *= -1
		value = ''
	req.res.cookie prefix + photoId, value,
		domain: req
		httpOnly: true
		maxAge: maxAge
		secure: (config.wornet.protocole is 'https')

deleteCookie = (req, photoId) ->
	setCookie req, photoId, '', true

PhotoPackage =

	photos: {}
	photosForCookieChecking: {}

	urlToId: (url) ->
		regExp = /\/img\/photo\/([0-9]+x)?([a-f0-9]{5,})(\/[^\/]+)?\.jpg(\?[A-Za-z0-9]*)?$/ig
		match = url.match regExp
		photoId = null
		if match
			photoId = match[0].replace regExp, '$2'
		photoId

	restricted: (req, photoId) ->
		! @allowedToSee req, photoId

	restrictedAndAllowedToSee: (req, photoId) ->
		token = req.cookie prefix + photoId
		photoId = strval photoId
		@photos[photoId] and @photos[photoId] is token

	allowedToSee: (req, photoId) ->
		photoId = strval photoId
		if @photosForCookieChecking[photoId]
			req.getHeader('cookie').indexOf(prefix + photoId + '=' + @photosForCookieChecking[photoId]) isnt -1
		else
			true

	forget: (req, photoId) ->
		photoId = strval photoId
		if @restrictedAndAllowedToSee req, photoId
			delete @photos[photoId]
			deleteCookie req, photoId

	publish: (req, photoId, statusId, lastSelectedAlbum = null, done) ->
		if "function" is typeof lastSelectedAlbum
			done = lastSelectedAlbum
			lastSelectedAlbum = null
		photoId = strval photoId
		if @restrictedAndAllowedToSee req, photoId
			values = {
				status: 'published'
				$push: statusList: statusId
				}.with if lastSelectedAlbum
					album: lastSelectedAlbum._id
			options =
				safe: true
			Photo.findByIdAndUpdate photoId, values, options, done
			@forget req, photoId
		else
			done new PublicError s("Non autorisé")

	fromAlbum: (id, done, columns = 'id photo thumb50 name') ->
		if done instanceof Array
			_done = columns
			columns = done
			done = _done
		Photo.find
			album: id
			status: 'published'
		.sort _id: 'asc'
		.select columns
		.exec (err, photos) ->
			if photos
				columns = columns.split /\s+/g
				photos = photos.map (photo) ->
					photo.columns columns
			done err, photos

	delete: (photoId, status = 'uploaded') ->
		photoId = strval photoId
		Photo.remove
			_id: photoId
			status: status
		, (err, count) ->
			if err
				throw err
			else
				delete @photos[photoId]

	deleteImages: (images) ->
		self = @
		each images, ->
			id = self.urlToId @src
			self.delete id, 'published'
			true

	add: (req, photoId) ->
		token = generateSalt 32
		setCookie req, photoId, token
		photoId = strval photoId
		unless @photos[photoId]
			@photos[photoId] = @photosForCookieChecking[photoId] = token
			redisClientEmitter.publish config.wornet.redis.defaultChannel,
				JSON.stringify(
					type: "addPhoto",
					message:
						photoId: photoId,
						token: token
				)
		self = @
		delay config.wornet.upload.ttl.seconds, ->
			if @photos[photoId] and @photos[photoId] is token
				self.delete photoId
				redisClientEmitter.publish config.wornet.redis.defaultChannel,
					JSON.stringify(
						type: "deletePhoto",
						message:
							photoId: photoId
					)

	refreshAlbum: (albumId) ->
		if albumRefreshes[albumId]
			clearTimeout albumRefreshes[albumId]
		albumRefreshes[albumId] = delay 500, ->
			Album.findById albumId, (err, album) ->
				if err
					warn err
				if album
					album.refreshPreview (err) ->
						if err
							warn err

module.exports = PhotoPackage
