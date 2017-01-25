'use strict'

###
Extend Object prototype
###

ObjectUtils =

    bind: (method, done = null) ->
        if done
            @[method] done.bind @
        else
            method.bind @

    updateById: (id, update, done) ->
        done ||= (err) ->
            if err
                throw err
        findById @, id, (err, self) ->
            if err
                done err
            else
                extend self, update
                self.save done

safeExtend Object.prototype, ObjectUtils

module.exports = ObjectUtils
