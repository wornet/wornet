module.exports = (schema) ->
	schema.virtual('createdAt').get ->
		Date.fromId @_id
