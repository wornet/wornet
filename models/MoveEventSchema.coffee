'use strict'

moveEventSchema = BaseSchema.extend
    type:
        type: String
        enum: [
            'public'
            'private'
        ]
        required: true
    creatorEntity:
        type: String
        enum: [
            'individual' # Un particulier
            'startup'
            'association'
            'company'
        ]
        required: true
    entityName:
        type: String
    title:
        type: String
        required: true
    startDate:
        type: Date
        required: true
    endDate:
        type: Date
    locality:
        country:
            type: String
            required: true
        address:
            type: String
            required: true
        city:
            type: String
            required: true
    description:
        type: String
        required: true
    nbParticipantMax:
        type: Number
        required: true
    acceptMode:
        type: String
        enum: [
            'manual'
            'auto'
        ]
        default: 'auto'
        required: true
    allowFriendInvite:
        type: Boolean
        required: true
        default: false
    tags: [
        type: String
    ]
    organizers:[
        type: ObjectId
        ref: 'UserSchema'
    ]
    participants:[
        type: ObjectId
        ref: 'UserSchema'
    ]
    invited:[
        type: ObjectId
        ref: 'UserSchema'
    ]
    bannerPhotoId:
        type: ObjectId
        ref: 'PhotoSchema'
    eventPhotoId:
        type: ObjectId
        ref: 'PhotoSchema'
    albumPhotoId:
        type: ObjectId
        ref: 'AlbumSchema'


module.exports = moveEventSchema
