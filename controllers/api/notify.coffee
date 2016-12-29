'use strict'

module.exports = (router) ->

    router.get '', (req, res) ->
        if req.user
            # Wait for new notifications
            NoticePackage.waitForJson req.user.id, req, res, req.user
        else
            delay 2.minutes, ->
                res.json()
