'use strict'

photos = {}

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
		token = req.cookie 'p:' + photoId
		photoId = strval photoId
		photos[photoId] and photos[photoId] is token

	allowedToSee: (req, photoId) ->
		token = req.cookie 'p:' + photoId
		photoId = strval photoId
		! photos[photoId] or photos[photoId] is token

	forget: (req, photoId) ->
		photoId = strval photoId
		if @restrictedAndAllowedToSee req, photoId
			delete photos[photoId]
			req.res.cookie 'p:' + photoId, '',
				domain: req
				signed: true
				maxAge: - 24 * 3600

	publish: (req, photoId) ->
		photoId = strval photoId
		if @restrictedAndAllowedToSee req, photoId
			Photo.updateById photoId, status: 'published'
			@forget req, photoId

	delete: (photoId, status = 'uploaded') ->
		photoId = strval photoId
		Photo.remove
			id: photoId
			status: status
		, (err, count) ->
			if !err and count
				photoDirectory = __dirname + '/../../public/img/photo/'
				fs.unlink photoDirectory + photoId + '.jpg'
				for size in sizes
					fs.unlink photoDirectory + size + 'x' + photoId + '.jpg'
				delete self.photos[photoId]

	add: (req, photoId) ->
		token = generateSalt 32
		req.res.cookie 'p:' + photoId, token,
			domain: req
			signed: true
		photoId = strval photoId
		unless photos[photoId]
			photos[photoId] = token
		self = @
		delay config.wornet.upload.ttl * 1000, ->
			if photos[photoId] and photos[photoId] is token
				self.delete photoId

module.exports = PhotoPackage
