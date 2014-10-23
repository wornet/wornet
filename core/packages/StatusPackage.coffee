'use strict'

StatusPackage =

	getRecentStatus: (req, res, data = {}) ->
		connectedPeople = req.user.friends.column '_id'
		connectedPeople.push req.user.id
		Status.find()
			.where 'author'
			.in connectedPeople
			.skip 0
			.limit 10
			.sort date: 'desc'
			.select '_id date author content'
			.exec (err, recentStatus) ->
				missingIds = []
				recentStatusPublicData = []
				if recentStatus and typeof recentStatus is 'object'
					recentStatus.each ->
						status = @toObject()
						author = strval @author
						if req.user.id is author
							status.author = req.user.publicInformations()
						else if (author = req.user.friends.findOne id: author)
							author = objectToUser author
							status.author = author.publicInformations()
						else
							missingIds.push author
						recentStatusPublicData.push status

				if missingIds.length
					console['warn'] 'It should not miss IDs'
				extend data,
					err: err
					recentStatus: recentStatusPublicData
				res.json data

	add: (req, done) ->
		if req.body.status and req.body.status.content
			Status.create
				author: req.user._id
				content: req.body.status.content
			, (err, status) ->
				unless err
					status = status.toObject()
					status.author = req.user.publicInformations()
					connectedPeople = req.user.friends.column '_id'
					NoticePackage.notify connectedPeople, null,
						action: 'status'
						status: status
				done err, status
		else
			done "Invalid status content"

module.exports = StatusPackage
