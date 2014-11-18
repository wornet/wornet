'use strict'

albumSchema = BaseSchema.extend
	name:
		type: String
		trim: true
		required: true
	description:
		type: String
		trim: true

albumSchema.methods.firstPhoto = (done, thumbSize = null) ->
	Photo.findOne album: @id, (err, photo) ->
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

module.exports = albumSchema
