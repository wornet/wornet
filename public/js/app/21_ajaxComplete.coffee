$document = $(document)
	# When receive back an AJAX request
	.ajaxComplete (event, xhr, settings) ->
		# POST is secured by CSRF tokens
		isPost = (settings.type is "POST")
		isJson = (settings.dataType? && settings.dataType.toLowerCase() is "json")
		if xhr.status isnt 0
			if isPost or isJson
				data = xhr.responseText
				# In JSON format
				if isJson
					try
						data = $.parseJSON data
					catch e
						data = null
					if typeof(data) isnt 'object' or data is null or typeof(data._csrf) is 'undefined'
						serverError()
					else
						if data.err
							console['log'] data.err
							if typeof data.err is 'object' and data.err.name
								switch data.err.name
									when "ValidationError"
										err = data.err.message + '<ul>'
										errors = data.err.errors
										unless errors.length
											errors = [errors]
										for error in errors
											err += '<li>' + safeHtml(error.name.message) + '</li>'
										err += '</ul>'
									else
										err = data.err.message || (data.err + '')
							else
								err = data.err + ''
							console['error'] err
							if isPost
								$('.errors').errors err
						if data.stack
							console['log'] data.stack
						_csrf = data._csrf
						$('head meta[name="_csrf"]').attr 'content', _csrf
				# In HTML format
				else
					# Get new CSRF token from meta tags given in the AJAX response
					_csrf = $(data).find('meta[name="_csrf"]').attr 'content'
			return
		return
