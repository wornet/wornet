'use strict'

photoSchema = OwnedSchema.extend
	album:
		type: ObjectId
		ref: 'AlbumSchema'
	statusList: [
		type: ObjectId
		ref: 'StatusSchema'
	]
	status:
		type: String
		default: 'uploaded'
		enum: [
			'uploaded'
			'published'
		]

photoSrc = (prefix) ->
	jpg(
		if @_id?
			'photo/' + (prefix || '') + @_id
		else
			'default-photo'
	)

photoSchema.virtual('path').get ->
	__dirname + '/../public/img/photo/' + @_id + '.jpg'

photoSchema.virtual('photo').get ->
	photoSrc.call @

photoSchema.virtual('thumb').get ->
	photoSrc.call @, '90x'

for size in config.wornet.thumbSizes
	photoSchema.virtual('thumb' + size).get ->
		photoSrc.call @, size + 'x'

photoSchema.pre 'remove', (done) ->
	count = @statusList.length
	do next = (err = null) ->
		if err
			done err
		else unless count--
			done()
	id = @id
	for statusId in @statusList
		Status.findById statusId, (err, status) ->
			if ! err and status
				images = status.images.filter (image) ->
					! (new RegExp '[x/]' + id + '\.jpg$').test image.src
				if images.length < status.images.length
					status.images = images
					if status.isEmpty()
						status.remove next
					else
						status.save next
				else
					next()
			else
				next err

photoSchema.post 'remove', ->
	photoDirectory = __dirname + '/../public/img/photo/'
	unlink photoDirectory + @id + '.jpg'
	for size in config.wornet.thumbSizes
		unlink photoDirectory + size + 'x' + @id + '.jpg'
	PhotoPackage.refreshAlbum @album

module.exports = photoSchema
