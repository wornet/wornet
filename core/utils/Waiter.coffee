'use strict'

watchedPlaces = {}

class Waiter
	userId: null
	watchPlaces: null
	req: null
	res: null
	constructor: (@userId, watchPlace, @req, @res) ->
		if @res._waiter
			console['log'] @res._waiter
			throw new Error "Waiter already attached"
		@res._waiter = [@, (new Error()).stack]
		if isstring watchPlace
			@watchPlaces = [watchPlace]
			Waiter.watchPlace watchPlace, @
		else
			watchPlace.getFriendsIds (err, friendIds) =>
				@watchPlaces = friendIds.map cesarLeft
					.with watchPlace.hashedId
				each @watchPlaces, (_, id) =>
					Waiter.watchPlace id, @

	unwatch: ->
		each @watchPlaces, (_, place) ->
			Waiter.unwatchPlace place, @

	respond: (err, notifications = []) ->
		if @timeoutKey
			NoticePackage.clearTimeout @timeoutKey
		@unwatch()
		req = @req
		res = @res
		userId = @userId
		unless notifications instanceof Array
			notifications = [[err, notifications]]
		if res._notifications
			res._notifications.merge notifications
		else
			res._notifications = notifications
			delay 50, ->
				req.session.reload (sessErr) ->
					if sessErr
						throw sessErr
					notifications = res._notifications
					mustRefreshFriends = false
					for notification in notifications
						if notification[1]
							if notification[1].askForFriend?
								test = hashedId: notification[1].askForFriend.hashedId
								unless (req.session.friendAsks || {}).has(test) or (req.session.friends || []).has(test)
									req.cacheFlush 'friends'
									req.user.friendAsks[notification[1].id] = notification[1].askForFriend
									req.session.user.friendAsks = req.user.friendAsks
									req.session.friendAsks = req.user.friendAsks
								delete notification[1].askForFriend
							if notification[1].userId?
								delete notification[1].userId
							if notification[1].deleteFriendAsk?
								delete req.user.friendAsks[notification[1].deleteFriendAsk]
								req.session.user.friendAsks = req.user.friendAsks
								req.session.friendAsks = req.user.friendAsks
								req.session.notifications = (req.session.notifications || []).filter (data) ->
									unless data[1]
										warn JSON.stringify(data) + ' does not contains [1] entry.'
										false
									else if typeof data[1] isnt 'object' or typeof data[1].hashedId is 'undefined'
										true
									else
										data[1].hashedId isnt cesarRight userId
								delete notification[1].deleteFriendAsk
							if notification[1].addFriend?
								req.addFriend notification[1].addFriend
								delete notification[1].addFriend
					data =
						notifications: notifications
						loggedFriends: req.getLoggedFriends()
					data.notifyStatus = if err
						data.err = err
						NoticePackage.ERROR
					else
						NoticePackage.OK
					req.refreshNotifications (notifications) ->
						if notifications.length
							req.session.notifications = notifications
						req.session.save (err) ->
							if err
								throw err
							res.json data

Waiter.respond = (place, err, notifications = []) ->
	if watchedPlaces[place]
		each watchedPlaces[place], ->
			@respond err, notifications
		delete watchedPlaces[place]

Waiter.watchPlace = (place, waiter) ->
	place += ''
	(watchedPlaces[place] ||= []).push waiter

Waiter.unwatchPlace = (place, waiter) ->
	place += ''
	if watchedPlaces[place] and watchedPlaces[place].length
		watchedPlaces[place] = watchedPlaces[place].filter (w) ->
			w isnt waiter
		unless watchedPlaces[place].length
			delete watchedPlaces[place]

module.exports = Waiter
