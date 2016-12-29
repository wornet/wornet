'use strict'

tries =
    ip: {}
    user: {}
    ipUser: {}

AntiBruteForcePackage =

    clean: ->
        now = time()
        for pattern, lists of tries
            duration = config.wornet.security.duration[pattern].minutes
            for key, list of lists
                list = t for t in list when now - t > duration
                if list.length
                    lists[key] = list
                else
                    delete lists[key]


    test: (ip, user, done) ->

        now = time()
        lockDuration = 0
        for pattern, lists of tries
            limit = config.wornet.security.limit[pattern]
            duration = config.wornet.security.duration[pattern]
            key = pattern
                .replace /[A-Z]/g, (letter) ->
                    '-' + letter.toLowerCase()
                .replace 'ip', ip
                .replace 'user', user
            list = (lists[key] ||= [])
            if list.length < limit
                list.push now
            else
                BruteForceLog.create
                    user: user
                    ip: ip
                    status: pattern
                if lockDuration < duration
                    lockDuration = duration

        if lockDuration
            done new PublicError s("Trop d'essais, veuillez patienter {count} minute.|Trop d'essais, veuillez patienter {count} minutes.", {}, lockDuration)
        else
            done null

setInterval AntiBruteForcePackage.clean, 5.minutes

module.exports = AntiBruteForcePackage
