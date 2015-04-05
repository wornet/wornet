'use strict'

bruteForceLogSchema = OwnedSchema.extend
	ip:
		type: String
		required: true
	status:
		type: String
		required: true
		enum: [
			'ip'
			'user'
			'ipUser'
		]

module.exports = bruteForceLogSchema
