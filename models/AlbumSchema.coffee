'use strict'

albumSchema = BaseSchema.extend
	user:
		type: ObjectId
		ref: 'UserSchema'
	name:
		type: String
		trim: true
		required: true
	description:
		type: String
		trim: true
	preview:
		type: Array

albumSchema.methods.refreshPreview = (save = false, done) ->
	album = @
	Photo.find
		album: album._id
		status: 'published'
	.sort '-_id'
	.limit 4
	.exec (err, photos) ->
		if err
			done err
		else
			album.preview = photos.column '_id'
			if save
				album.save (err) ->
					if err
						done err
					else
						done null, photos
			else
				done null, photos

albumSchema.methods.firstPhoto = (done, thumbSize = null) ->
	Photo.findOne
		album: @id
		status: 'published'
	, (err, photo) ->
		if err
			done err
		else
			if thumbSize isnt null
				prefix = thumbSize + 'x'
			done null, '/img/photo/' + (prefix || '') + photo._id +'.jpg'

albumSchema.methods.firstThumb50 = (done) ->
	@firstPhoto done, 50

albumSchema.methods.firstThumb90 = (done) ->
	@firstPhoto done, 90

albumSchema.methods.firstThumb200 = (done) ->
	@firstPhoto done, 200

albumSchema.pre 'save', (next) ->
	if @isModified 'name'
		name = @name
		Status.find album: @_id, (err, statusList) ->
			if statusList
				statusList.each ->
					@albumName = name
					@save()
					true

	next()


module.exports = albumSchema
