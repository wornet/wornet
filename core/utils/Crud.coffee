###
C.R.U.D. = Create, Read, Update and Delete
With HTTP protocole, we use respectively PUT, GET, POST, DELETE
(PUT and DELETE are emulate in overriding method with _method POST param)
For example, add, see, modify and remove photos in an album page:

---------------------------------------------------------

controllers/album.coffee
	(new Crud router)
		# PUT /album
		.put (req, res) ->
			Photo.create (dbError, createdPhoto) ->
				res.json # AJAX response
					error: dbError
					photo: createdPhoto
		# GET /album
		.get (req, res) ->
			Photo.find user: req.user._id, (dbError, photosList) ->
				res.render 'album/photos' # Render Jade view
					error: dbError
					photos: photosList
		# POST /album
		.post (req, res) ->
			photoData = req.body.photo
			Photo.findById photoData.id, (dbError, updatedPhoto) ->
				res.json # AJAX response
					error: dbError
					photo: updatedPhoto
		# DELETE /album
		.delete (req, res) ->
			photoData = req.body.photo
			Photo.remove _id: photoData.id, (dbError) ->
				res.json # AJAX response
					error: dbError

---------------------------------------------------------

You can also ignore used method in using all method:

controllers/stuff.coffee
	(new Crud router).all (req, res, method) ->
		# This will be executed for all requests of /stuff URL (including PUT, DELETE, GET and POST methods):
		res.end "You try to access /stuff URL using " + method + " method"
###


class Crud
	constructor: (router, url = '/') ->
		@url = url
		@router = router

	put: (cb) ->
		@router.put @url, cb
		@

	get: (cb) ->
		@router.get @url, cb
		@

	post: (cb) ->
		@router.post @url, cb
		@

	delete: (cb) ->
		@router.delete @url, cb
		@

	all: (done) ->
		cb = (req, res) ->
			done req, res, req.method
		@get cb
		@post cb
		@put cb
		@delete cb
		@

module.exports = Crud