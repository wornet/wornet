'use strict'

commentSchema = PostSchema.extend
    attachedStatus:
        type: ObjectId
        ref: 'StatusSchema'
        required: true

commentSchema.pre 'save', (next) ->
    if empty(@content) and empty(@images) and empty(@videos) and empty(@links)
        next new PublicError s("Ce commentaire est vide")
    else
        findById Status, @attachedStatus, (err, status) =>
            if err
                next err
            else if status
                at = status.at || status.author
                if equals at, @author
                    next()
                else
                    Friend.findOne
                        status: 'accepted'
                        $or: [
                            askedFrom: at
                            askedTo: @author
                        ,
                            askedTo: at
                            askedFrom: @author
                        ], (err, friend) =>
                            if err
                                next err
                            else if friend
                                next()
                            else
                                Follow.findOne
                                    followed: at
                                    follower: @author
                                , (err, follow) =>
                                    if err
                                        next err
                                    else if follow
                                        next()
                                    else
                                        next new Error s("Vous ne pouvez poster que sur les profils de vos amis ou abonnements")
            else
                next new Error s("Le statut est introuvable")


module.exports = commentSchema
