$.fn.extend
	# Append alerts/messages to the given jQuery block
	# Then slide them out
	messages: (messages, type = 'info') ->
		messages ||= "Info"
		if typeof(messages) isnt 'object'
			messages = [messages]
		@html('') # Get and empty the #loginErrors block
		# Append each error
		for message in messages
			@append('<div class="alert alert-' + type + '">' + message + '</div>')
		# Close (instantanly) the error block
		@slideUp(0).slideDown('fast')
	# Append warnings to the given jQuery block
	# Then slide them out
	infos: (infos) ->
		@messages infos || "Information", 'info'
	# Append warnings to the given jQuery block
	# Then slide them out
	warnings: (warnings) ->
		@messages warnings || "Attention", 'warning'
	# Append errors to the given jQuery block
	# Then slide them out
	errors: (errors) ->
		if (errors and errors isnt SERVER_ERROR_DEFAULT_MESSAGE) or navigator.onLine
			@messages errors || "Erreur", 'danger'
	# Append success messages to the given jQuery block
	# Then slide them out
	success: (messages) ->
		@messages messages || "Succès", 'success'
	# To permit to a 0 opacity HTML element to fade
	readyToFade: ->
		if @css('opacity') is '0'
			@css('opacity', '1').fadeOut(0)
		@
	# Circular progress load animation
	circularProgress: (ratio, color) ->
		color ||= ($('<div class="ref-color"></div>').css('color') || '#ff8800')
		bgCol = @css('background-color')
		if ratio < 0.5
			@css('background-image', 'linear-gradient(90deg, ' + bgCol + ' 50%, transparent 50%, transparent), linear-gradient(' + Math.round(360 * ratio + 90) + 'deg, ' + color + ' 50%, ' + bgCol + ' 50%, ' + bgCol + ')')
		else
			@css('background-image', 'linear-gradient(' + Math.round(90 + 360 * ratio) + 'deg, ' + color + ' 50%, transparent 50%, transparent), linear-gradient(270deg, ' + color + ' 50%, transparent 50%, transparent)')
	# Get date id if the element contains [data-date] within it or its children
	dateId: (defaultValue = null) ->
		$date = $ @
		unless $date.is '[data-date]'
			$date = $date.find '[data-date]:first'
		date = $date.attr 'data-date'
		if date and date.length
			date.replace /["']/g, ''
		else
			defaultValue
	# Get date if the element contains [data-date] within it or its children
	date: (defaultValue = null) ->
		dateId = @dateId()
		if dateId
			date = (if /^[0-9a-f]+$/i.test dateId
					Date.fromId dateId
				else
					new Date dateId
			)
			if date.isValid()
				date
			else
				defaultValue
		else
			defaultValue
	# Force size of a box to specified ratio or to ratio embeded in data attribute
	ratio: (r) ->
		@each ->
			$block = $ @
			ratio = (r || $block.data 'ratio') * 1
			unless isNaN(ratio)
				$block.height $block.width() / ratio
			return
	# Update the src attribute of a thumb and all other thumbs with the same id
	thumbSrc: (src) ->
		userThumb = @data 'user-thumb'
		if userThumb
			src = src.replace /\/photo\/[0-9]+x/g, '/photo/'
			$('img[data-user-thumb="' + userThumb + '"]').each ->
				$img = $ @
				thumbSize = $img.data 'thumb-size'
				$img.prop 'src',
					if thumbSize
						src.replace /\/photo\//g, '/photo/' + thumbSize + 'x'
					else
						src
		@
