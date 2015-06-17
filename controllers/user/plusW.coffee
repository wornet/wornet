'use strict'

module.exports = (router) ->

	router.put '', (req, res) ->
		idStatus = req.data.status
		idUser = req.user._id
		PlusW.create
			user: idUser
			status: idStatus
		, (err, plusw) ->
			if err
				res.serverError err
			if plusw
				Status.findOne
					_id: idStatus
				, (err, status) ->
					if err
						res.serverError err
					if !status.nbLike
						newNbLike = 1
					else
						newNbLike = status.nbLike + 1

					Status.update
						_id: idStatus
					,
						nbLike: newNbLike
					, (err, status) ->
						if err
							res.serverError err
						else
							res.json {'newNbLike': newNbLike}

	router.delete '', (req, res) ->
		idStatus = req.data.status
		idUser = req.user._id
		PlusW.remove
			user: idUser
			status: idStatus
		, (err) ->
			if err
				res.serverError err
			else
				Status.findOne
					_id: idStatus
				, (err, status) ->
					if err
						res.serverError err
					if !status.nbLike
						newNbLike = 0
					else
						newNbLike = status.nbLike - 1
					Status.update
						_id: idStatus
					,
						nbLike: newNbLike
					, (err, status) ->
						if err
							res.serverError err
						else
							res.json {'newNbLike': newNbLike}
