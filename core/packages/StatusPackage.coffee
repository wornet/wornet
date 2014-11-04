'use strict'

StatusPackage =

	getRecentStatus: (req, res, id = null, data = {}) ->
		req.getFriends (err, friends, friendAsks) ->
			id = req.getRequestedUserId id
			connectedPeople = friends.column '_id'
			connectedPeopleAndMe = connectedPeople.copy()
			connectedPeopleAndMe.push req.user.id
			if connectedPeopleAndMe.contains id
				Status.find $or: [
						$and: [
							author: $in: connectedPeople
							at: req.user.id
						]
					,
						$and: [
							author: req.user.id
							at: null
						]
					]
					.where 'author'
					.in connectedPeople
					.skip 0
					.limit 10
					.sort date: 'desc'
					.select '_id date author content'
					.exec (err, recentStatus) ->
						if err
							res.serverError err
						else
							missingIds = []
							recentStatusPublicData = []
							if recentStatus and typeof recentStatus is 'object'
								recentStatus.each ->
									status = @toObject()
									author = strval @author
									if req.user.id is author
										author = null
									if author is null
										status.author = req.user.publicInformations()
									else if (author = friends.findOne id: author)
										author = objectToUser author
										status.author = author.publicInformations()
									else
										missingIds.push author
									recentStatusPublicData.push status

							if missingIds.length
								console['warn'] 'It should not miss IDs'
							data.recentStatus = recentStatusPublicData
							res.json data
			else
				res.serverError new Error "You can't see the status of this profile"

	add: (req, done) ->
		if req.body.status and req.body.status.content
			try
				Status.create
					author: req.user._id
					at: req.body.at || null
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
			catch err
				done err
		else
			done "Invalid status content"

module.exports = StatusPackage
