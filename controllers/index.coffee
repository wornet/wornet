'use strict'

module.exports = (router) ->

    router.get '/push-hook', (req, res) ->

        exec 'cd /var/www/nodejs/wornet/int'
        exec 'git pull'
        exec 'npm i'
