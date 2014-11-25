
$document = $(document)
	# When receive back an AJAX request
	.ajaxComplete (event, xhr, settings) ->
		# POST is secured by CSRF tokens
		isPost = (settings.type is "POST")
		isJson = (settings.dataType? && settings.dataType.toLowerCase() is "json")
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

# All global events
# [ [ "events to catch", "selector to target", callbackFunction ], ... ]
$.each [
	[
		'focus'
		'.form-control'
		($field) ->
			$field.prev('.tooltip').readyToFade().fadeIn 'fast'
			return
	]
	[
		'blur'
		'.form-control'
		($field) ->
			$field.prev('.tooltip').fadeOut 'fast'
			return
	]
	[
		'keyup focus change click'
		'.check-pass'
		($field) ->
			$password = $field.find 'input[type="password"]'
			$security = $field.find('.pass-security').removeClass 'verylow low medium high veryhigh'
			strongness = passwordStrongness $password.val()
			switch
				when strongness > 10000000000000000
					$security.addClass 'veryhigh'
				when strongness > 10000000000000
					$security.addClass 'high'
				when strongness > 1000000000
					$security.addClass 'medium'
				when strongness > 1000000
					$security.addClass 'low'
				else
					$security.addClass 'verylow'
			return
	]
	[
		'error'
		'img.upload-thumb'
		($thumb) ->
			$input = $thumb.parent().find 'input.upload'
			$('.errors').errors $input.data 'error'
			return
	]
	[
		'error load'
		'img.upload-thumb'
		($thumb) ->
			$thumb.parent().find('.loader').remove()
			return
	]
	[
		'change'
		'input.upload'
		($input) ->
			$parent = $input.parent()
			$thumb = $parent.find 'img.upload-thumb'
			$('<div class="loader"></div>').appendTo($parent).fadeOut(0).fadeIn 'fast'
			$input.parents('form').submit()
			return
	]
	[
		'load'
		'iframe'
		($iframe) ->
			name = $iframe.attr 'name'
			$form = $ 'form[target="' + name + '"]'
			$img = []
			$loader = $form.find '.loader'
			$loader.fadeOut 'fast', $loader.remove
			if $form.length
				$img = $ 'img', $iframe.prop('contentWindow')
			if $img.length && $img[0].width > 0
				$form.find('img.upload-thumb').prop 'src', $img.prop 'src'
			else
				$('.errors').errors $form.find('input.upload').data 'error'
			return
	]
	[
		'submit'
		'#profile-photo'
		($form, e) ->
			$img = $form.find 'img.upload-thumb'
			$img.fadeOut('fast')
			if typeof(FormData) is 'function'
				$progress = $form.find '.progress-radial'
				prevent e
				formData = new FormData()
				file = $form.find('input[type="file"]')[0].files[0]
				formData.append 'photo', file
				formData.append '_csrf', $('head meta[name="_csrf"]').attr('content')

				xhr = new XMLHttpRequest()
				xhr.open 'POST', $form.prop('action'), true

				xhr.upload.onprogress = (e) ->
					if e.lengthComputable
						$progress.circularProgress e.loaded / e.total

				xhr.onerror = ->
					$error = $(@responseText)
					unless $error.is('.error')
						$error = $error.find '.error'
					$loader = $form.find '.loader'
					$loader.fadeOut 'fast', $loader.remove
					$('.errors').errors $error.html()

				xhr.onload = ->
					$newImg = $(@responseText
						.replace /[\n\r\t]/g, ''
						.replace /^.*<body[^>]*>/ig, ''
						.replace /<\/body>.*$/ig, ''
					)
					unless $newImg.is('.error') or $newImg.is('img')
						$newImg = $newImg.find 'img'
					if $newImg.is('img')
						newSource = $newImg.attr('src')
						$img.fadeOut 'fast', ->
							$loader = $form.find '.loader'
							$loader.fadeOut 'fast', $loader.remove
							$img.attr('src', newSource).fadeIn('fast')
					else
						@onerror()

				xhr.send formData
				false
			else
				true
	]
	[
		'click'
		'[data-toggle="lightbox"]'
		($btn, e) ->
			$btn.ekkoLightbox()
			prevent e
	]
	[
		'touchstart',
		'img'
		($, e) ->
			e.preventDefault()
			return
	]
	[
		'click'
		'[data-click]'
		($btn) ->
			i = 0
			params = while typeof (param = $btn.data("params[" + (i++) + "]")) isnt "undefined"
				param
			$target = $ $btn.data 'target'
			$target[$btn.data 'click'].apply $target, params
			return
	]
	[
		'click'
		'[data-ask-for-friend]'
		($btn, e) ->
			Ajax.post '/user/friend', data: userId: $btn.data 'ask-for-friend'
			if $btn.is '.destroyable'
				$btn.fadeOut ->
					$btn.remove()
			prevent e
	]
	[
		'click'
		'.accept-friend'
		($btn, e) ->
			$message = $btn.parents '.friend-ask'
			$friends = $ '#friends'
			if exists $friends
				$li = $('<li>').appendTo $friends
				$a = $message.find 'a'
				if exists $a
					$a.clone(true).appendTo($li).fadeOut(0).fadeIn()
				else
					$img = $message.find 'img'
					if exists $img
						$a = $ '<a>'
						$a.attr('href', '/user/profile/' + $img.data('id') + '/' + encodeURIComponent($img.prop('alt')))
						$img.clone(true).appendTo $a
						$a.appendTo($li).fadeOut(0).fadeIn()
				numberOfFriends = $friends.find('li').length
				s = textReplacements
				text = s("({number} ami)|({number} amis)", { number: numberOfFriends }, numberOfFriends)
				$('.numberOfFriends').text text
			$message.find('.shift').slideUp()
			$message.find('.if-accepted').slideDown()
			delay 3000, ->
				$message.slideUp ->
					$(@).remove()
					return
				return
			id = $message.data 'id'
			Ajax.post '/user/friend/accept', data: id: id
			$('.friend-ask[data-id="' + id + '"]').each ->
				$this = $ @
				$li = $this.parents 'li:first'
				if exists $li
					$li.remove()
				else
					$this.remove()
				return
			refreshPill()
			cancel e
	]
	[
		'click'
		'.ignore-friend'
		($btn, e) ->
			$message = $btn.parents '.friend-ask'
			$message.slideUp ->
				$(@).remove()
				return
			id = $message.data 'id'
			Ajax.post '/user/friend/ignore', data: id: id
			$('.friend-ask[data-id="' + id + '"]').each ->
				$this = $ @
				$li = $this.parents 'li:first'
				if exists $li
					$li.remove()
				else
					$this.remove()
				return
			refreshPill()
			cancel e
	]
	[
		'click'
		'.notifications ul a'
		($a, e) ->
			unless $a.is '[data-id]'
				dateId = $a.dateId()
				if dateId
					Ajax.get '/user/notify/read/' + dateId, (data) ->
						notificationsService.setNotifications notifications
			if $a.is '.friend-accepted'
				true
			else
				unless $a.is '.friend-ask'
					$a.parents('li:first').remove()
					refreshPill()
				cancel e
	]
	[
		'click'
		'a[href]'
		($a, e) ->
			href = $a.prop('href').replace /#.*$/g, ''
			if href is '/user/logout'
				for key in ['chats']
					if window.sessionStorage and sessionStorage[key]
						delete sessionStorage[key]
			return true
			if href.length and href.charAt(0) isnt '#' and Ajax.page href, true
				cancel e
			else
				true
	]
	[
		'click'
		'.profile-edit-btn'
		($a, e) ->
			$('.profile-edit').removeClass 'hidden'
			$('.profile-display').addClass 'hidden'
			cancel e
	]
	[
		'click'
		'[give-focus]'
		($a) ->
			sel = $a.attr 'give-focus'
			delay 1, ->
				$(sel).focus()
				return
			return
	]

], ->
	params = @
	$document.on params[0], params[1], ->
		args = Array.prototype.slice.call arguments
		args.unshift $ @
		params[2].apply @, args
	return
