'use strict'

StatusPackage =

	getRecentStatusForRequest: (req, res, id = null, data = {}) ->
		onProfile = !!req.query.at
		@getRecentStatus req, res, id, data, onProfile

	getRecentStatus: (req, res, id = null, data = {}, onProfile = false) ->
		req.getFriends (err, friends, friendAsks) ->
			id = req.getRequestedUserId id
			me = req.user.id
			connectedPeople = friends.column 'id'
			connectedPeopleAndMe = connectedPeople.copy()
			connectedPeopleAndMe.push req.user.id
			console.log onProfile
			where = (if onProfile
				if id is me
					$or: [
						author: $in: connectedPeople
						at: me
					,
						author: me
						at: null
					]
				else
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
					author: $in: connectedPeople
					at: null
				,
					author: id
					at: null
				]
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
								req.getKnownUsersByIds missingIds, (err, usersMap) ->
									if err
										res.serverError err
									else
										recentStatus.each ->
											status = @toObject()
											if @at is @author
												@at = null
											#console.log [74, usersMap, @author]
											status.author = usersMap[strval @author].publicInformations()
											if @at
												console.log [77, usersMap, @at]
												status.at = usersMap[strval @at].publicInformations()
											recentStatusPublicData.push status
											true
										data.recentStatus = recentStatusPublicData
										res.json data
							else
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
