'use strict'

module.exports = (router) ->

    router.get '/chess.js', (req, res) ->
        fs.readFile __dirname + '/../node_modules/chess.js/chess.js', (err, data) ->
            res.set 'Content-Type', 'application/javascript; charset=utf-8'
            res.send data

    router.get '/chess.min.js', (req, res) ->
        fs.readFile __dirname + '/../node_modules/chess.js/chess.min.js', (err, data) ->
            res.set 'Content-Type', 'application/javascript; charset=utf-8'
            res.send data

    router.get '/chess/:id', (req, res) ->
        findOne User,
            _id: cesarRight req.params.id
        , (err, user) ->
            if err
                res.serverError err
                return

            res.render 'game/chess', friend: user
