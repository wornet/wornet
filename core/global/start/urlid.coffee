'use strict'

app.onready ->

    attributeId = (users, inc) ->
        if !inc
            inc = 0
        userToModify = users[inc]
        if !userToModify
            return
        regexToCheck =  new RegExp replaceAccent ( '^' + userToModify.name.first + '\.' + userToModify.name.last).toLowerCase()
        User.count
            uniqueURLID: regexToCheck
        , (err, count) ->
            warn err if err
            urlId = if count
                replaceAccent (userToModify.name.first + '.' + userToModify.name.last + '.' + count).toLowerCase()
            else
                replaceAccent (userToModify.name.first + '.' + userToModify.name.last).toLowerCase()
            User.update
                _id: userToModify._id
            ,
                uniqueURLID: urlId
            , (err, newUser) ->
                warn err if err
                console['log'] "user : " + userToModify._id + " Nom : " + userToModify.name.full
                console['log'] "uniqueURLID attribué : " + urlId
                attributeId users, inc + 1

    User.find
        $or: [
            uniqueURLID:
                $exists: false
        ,
            uniqueURLID: null
        ]
    , (err, users) ->
        warn err if err
        if users
            attributeId users
