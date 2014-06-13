'use strict'

module.exports = (router) ->

    model = new IndexModel()

    router.get '/', (req, res) ->

        res.render 'index', model
