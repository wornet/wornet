$.fn.extend
	# Append alerts/messages to the given jQuery block
	# Then slide them out
	messages: (messages, type = 'info') ->
		messages = messages || "Info"
		if typeof(messages) isnt 'object'
			messages = [messages]
		@.html('') # Get and empty the #loginErrors block
		# Append each error
		for message in messages
			@.append('<div class="alert alert-' + type + '">' + message + '</div>')
		# Close (instantanly) the error block
		@.slideUp(0).slideDown('fast')
	# Append errors to the given jQuery block
	# Then slide them out
	errors: (errors) ->
		@messages errors || "Erreur", 'danger'
	# Append success messages to the given jQuery block
	# Then slide them out
	success: (messages) ->
		@messages messages || "Succès", 'success'
	# To permit to a 0 opacity HTML element to fade
	readyToFade: ->
		if @.css('opacity') is '0'
			@.css('opacity', '1').fadeOut(0)
		@
	# Circular progress load animation
	circularProgress: (ratio, color) ->
		color = color || ($('<div class="ref-color"></div>').css('color') || '#ff8800')
		bgCol = @.css('background-color')
		if ratio < 0.5
			@.css('background-image', 'linear-gradient(90deg, ' + bgCol + ' 50%, transparent 50%, transparent), linear-gradient(' + Math.round(360 * ratio + 90) + 'deg, ' + color + ' 50%, ' + bgCol + ' 50%, ' + bgCol + ')')
		else
			@.css('background-image', 'linear-gradient(' + Math.round(90 + 360 * ratio) + 'deg, ' + color + ' 50%, transparent 50%, transparent), linear-gradient(270deg, ' + color + ' 50%, transparent 50%, transparent)')
