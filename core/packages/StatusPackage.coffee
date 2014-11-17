'use strict'

StatusPackage =

	getRecentStatusForRequest: (req, res, id = null, data = {}) ->
		onProfile = !!req.data.at
		@getRecentStatus req, res, id, data, onProfile

	getRecentStatus: (req, res, id = null, data = {}, onProfile = false) ->
		req.getFriends (err, friends, friendAsks) ->
			id = req.getRequestedUserId id
			me = req.user.id
			connectedPeople = friends.column 'id'
			connectedPeopleAndMe = connectedPeople.copy()
			connectedPeopleAndMe.push req.user.id
			where = (if onProfile
				if config.wornet.onlyAuthoredByAFriend
					$or: [
						author:
							$in: connectedPeopleAndMe
							$ne: id
						at: id
					,
						author: id
						at: null
					]
				else
					$or: [
						at: id
					,
						author: id
						at: null
					]
			else
				author: $in: connectedPeopleAndMe
			)
			if connectedPeopleAndMe.contains id
				Status.find where
					.skip 0
					.limit 10
					.sort date: 'desc'
					.select '_id date author at content'
					.exec (err, recentStatus) ->
						if err
							res.serverError err
						else
							missingIds = []
							recentStatusPublicData = []
							if recentStatus and typeof recentStatus is 'object'
								add = (val) ->
									val = strval val
									unless missingIds.contains val
										missingIds.push val
								recentStatus.each ->
									if @at
										add @at
									add @author
									true
								searchInDataBase = !! config.wornet.onlyAuthoredByAFriend
								done = (err, usersMap) ->
									if err
										res.serverError err
									else
										recentStatus.each ->
											status = @toObject()
											if @at is @author
												@at = null
											status.author = usersMap[strval @author].publicInformations()
											if @at
												status.at = usersMap[strval @at].publicInformations()
											recentStatusPublicData.push status
											true
										data.recentStatus = recentStatusPublicData
										res.json data
								req.getUsersByIds missingIds, done, searchInDataBase
							else
								data.recentStatus = recentStatusPublicData
								res.json data
			else
				res.serverError new Error "You can't see the status of this profile"

	add: (req, done) ->
		if req.data.status and req.data.status.content
			try
				Status.create
					author: req.user._id
					at: req.data.at || null
					content: req.data.status.content
				, (err, status) ->
					unless err
						status = status.toObject()
						status.author = req.user.publicInformations()
						next = (usersToNotify) ->
							NoticePackage.notify usersToNotify, null,
								action: 'status'
								status: status
						if status.at is null
							req.getFriends (err, friends, friendAsks) ->
								next friends.column '_id'
						else
							next [status.at]
					done err, status
			catch err
				done err
		else
			done "Invalid status content"

module.exports = StatusPackage
