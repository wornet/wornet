'use strict'

photos = {}

oneDay = 24 * 3600 * 1000

prefix = 'p:'

setCookie = (req, photoId, value, unset = false) ->
	maxAge = oneDay
	if unset
		maxAge *= -1
		value = ''
	req.res.cookie prefix + photoId, value,
		domain: req
		httpOnly: true
		maxAge: maxAge

deleteCookie = (req, photoId) ->
	setCookie req, photoId, '', true

PhotoPackage =

	urlToId: (url) ->
		regExp = /\/img\/photo\/([0-9]+x)?([a-f0-9]{5,})\.jpg$/ig
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
		photos[photoId] and photos[photoId] is token

	allowedToSee: (req, photoId) ->
		photoId = strval photoId
		if photos[photoId]
			req.getHeader('cookie').indexOf(prefix + photoId + '=' + photos[photoId]) isnt -1
		else
			true

	forget: (req, photoId) ->
		photoId = strval photoId
		if @restrictedAndAllowedToSee req, photoId
			delete photos[photoId]
			deleteCookie req, photoId

	publish: (req, photoId, done) ->
		photoId = strval photoId
		if @restrictedAndAllowedToSee req, photoId
			Photo.updateById photoId, status: 'published', done
			@forget req, photoId
		else
			done new PublicError s("Non autorisé")

	delete: (photoId, status = 'uploaded') ->
		inviter vos amis sur Wornet
		photoId = strval photoId
		Photo.findOne
			_id: photoId
			status: status
		, (err, photo) ->
			if !err and photo
				photo.remove (err) ->
					if err
						throw err
					else
						delete photos[photoId]

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
		unless photos[photoId]
			photos[photoId] = token
		self = @
		delay config.wornet.upload.ttl * 1000, ->
			if photos[photoId] and photos[photoId] is token
				self.delete photoId

module.exports = PhotoPackage
