'use strict'

class PublicError
	constructor: (msg, err) ->
		@msg = msg
		if config.env.development
			@stack = (err || new Error(msg)).stack
			if err
				@stack = err + '\n' + @stack
	toString: ->
		@msg

module.exports = PublicError
