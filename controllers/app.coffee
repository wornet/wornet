'use strict'

module.exports = (router) ->

    router.get '/:id/:name', (req, res) ->
        App.findByPublicKey req.params.id, (err, app) ->
            if err
                res.notFound()
            else
                res.render 'app', app: app
