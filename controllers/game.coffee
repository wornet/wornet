'use strict'

module.exports = (router) ->

    router.get '/chess/:id', (req, res) ->
        findOne User,
            _id: cesarRight req.params.id
        , (err, user) ->
            if err
                res.serverError err
                return

            res.render 'game/chess', friend: user
