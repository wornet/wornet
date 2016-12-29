'use strict'

certificationAskSchema = OwnedSchema.extend
    userType:
        type: String
        enum: [
            "particular"
            "business"
            "association"
        ]
    userFirstName:
        type: String
        required: true
    userLastName:
        type: String
        required: true
    userEmail:
        type: String
        required: true
    userTelephone:
        type: String
        required: true
    businessName:
        type: String
    message:
        type: String
        trim: true
    proof:
        name:
            type: String
            trim: true
        src:
            type: String
            trim: true
    status:
        type: String
        enum: [
            "pending"
            "approved"
            "refused"
        ]

module.exports = certificationAskSchema
