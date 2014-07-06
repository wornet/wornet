class Crud
	constructor: (router, url = '/') ->
		@url = url
		@router = router

	get: (cb) ->
		@router.get @url, cb

	post: (cb) ->
		@router.post @url, cb

	put: (cb) ->
		@router.put @url, cb

	delete: (cb) ->
		@router.delete @url, cb

	all: (done) ->
		cb = (req, res) ->
			done req, res, req.method
		@get cb
		@post cb
		@put cb
		@delete cb

module.exports = Crud