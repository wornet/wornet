
birthDaysTask =

    notifyAllFriends: (err, friends) ->
        if friends and friends.getLength() > 0
            img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: @
            NoticePackage.notify friends.column('id'), null,
                action: 'notice'
                notice: [
                    img +
                    jd 'span(data-href="/' +
                    @uniqueURLID + '") ' +
                    s("Aujourd'hui c'est l'anniversaire de votre ami {username}.", username: @fullName)
                , 'birthday', @_id, null, @_id]

    wishBirthDays: ->
        today = new Date()
        if today.getHours() is 23
            today.addHours 1
        User.aggregate [
            $project:
                name: 1
                photoId: 1
                birthDate: 1
                maskBirthDate: 1
                day: $dayOfMonth: "$birthDate"
                month: $month: "$birthDate"
        ,
            $match:
                day: today.getDate()
                month: today.getMonth() + 1
                maskBirthDate: $in: [false, null]
        ], (err, users) ->
            each users, ->
                user = objectToUser @
                user.getFriends birthDaysTask.notifyAllFriends.bind(user), true

    waitForMidnight: ->
        nextMidnight = (new Date).tomorrow().midnight()
        delay nextMidnight - time(), birthDaysTask.wishBirthDays

birthDaysTask.waitForMidnight()

module.exports = birthDaysTask
