'use strict'

commentListResponse = (err, commentList) ->
    if err
        @serverError err
    else
        @json commentList

module.exports = (router) ->

    router.put '/add', (req, res) ->
        if !req.user
            res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
        CommentPackage.put req, res, commentListResponse.bind res

    router.get '', (req, res) ->
        CommentPackage.getRecentCommentForRequest req, res, req.data.statusIds, commentListResponse.bind res

    router.delete '', (req, res) ->
        if !req.user
            res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
        me = req.user.id
        userComment = req.data.comment

        next = ->
            Comment.remove
                _id: userComment._id
            , (err) ->
                if err
                    res.serverError err
                else
                    res.json()

        if userComment and userComment._id
            Comment.findOne
                _id: userComment._id
            , (err, comment) ->
                if err
                    res.serverError err
                else if comment
                    if equals comment.author, me
                        next()
                    else
                        if comment.attachedStatus
                            Status.count
                                _id: comment.attachedStatus
                                $or: [
                                    author: me
                                    at: null
                                ,
                                    at: me
                                ]
                            , (err, nbStatus) ->
                                if err
                                    res.serverError err
                                else if !nbStatus
                                    res.serverError "You don't have the right to remove this comment"
                                else
                                    next()
                        else
                            res.serverError 'No status on comment'
                else
                    res.serverError 'No comment to update'

    router.post '', (req, res) ->
        if !req.user
            res.serverError new PublicError s("Vous devez vous connecter pour effectuer cette action.")
        userComment = req.data.comment
        me = req.user.id
        if userComment and userComment._id
            Comment.update
                _id: userComment._id
                author: me
            ,
                content: userComment.content || ''
            , (err, comment) ->
                if err
                    res.serverError err
                else if !comment
                    res.serverError "You don't have the right to update this comment"
                else
                    CommentPackage.getRecentCommentForRequest req, res, [userComment.attachedStatus._id], commentListResponse.bind res
        else
            res.serverError 'No comment to Update'
