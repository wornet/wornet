'use strict'

module.exports = (router) ->

	router.get '', (req, res) ->
		# Wait for new notifications
		NoticePackage.waitForJson req.user.id, req, res, req.user
