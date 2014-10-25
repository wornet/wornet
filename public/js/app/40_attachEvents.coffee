$document = $(document)
	# When receive back an AJAX request
	.ajaxComplete (event, xhr, settings) ->
		# POST is secured by CSRF tokens
		if settings.type is "POST"
			data = xhr.responseText
			# In JSON format
			if settings.dataType? && settings.dataType.toLowerCase() is "json"
				try
					data = $.parseJSON data
				catch e
					data = null
				if typeof(data) isnt 'object' or data is null or typeof(data._csrf) is 'undefined'
					serverError()
				else
					if data.err
						err = data.err
						$('.errors').errors err
					_csrf = data._csrf
					$('head meta[name="_csrf"]').attr 'content', _csrf
			# In HTML format
			else
				# Get new CSRF token from meta tags given in the AJAX response
				_csrf = $(data).find('meta[name="_csrf"]').attr 'content'

# All global events
# [ [ "events to catch", "selector to target", callbackFunction ], ... ]
$.each [
	[
		'focus'
		'.form-control'
		($field) ->
			$field.prev('.tooltip').readyToFade().fadeIn 'fast'
	]
	[
		'blur'
		'.form-control'
		($field) ->
			$field.prev('.tooltip').fadeOut 'fast'
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
	]
	[
		'error'
		'img.upload-thumb'
		($thumb) ->
			$input = $thumb.parent().find 'input.upload'
			$('.errors').errors $input.data 'error'
	]
	[
		'error load'
		'img.upload-thumb'
		($thumb) ->
			$thumb.parent().find('.loader').remove()
	]
	[
		'change'
		'input.upload'
		($input) ->
			$parent = $input.parent()
			$thumb = $parent.find 'img.upload-thumb'
			$('<div class="loader"></div>').appendTo($parent).fadeOut(0).fadeIn 'fast'
			$input.parents('form').submit()
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
					$newImg = $(@responseText)
					unless $newImg.is('.error') || $newImg.is('img')
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
			$li = $('<li></li>').appendTo('#friends')
			$message.find('a').clone(true).fadeOut(0).fadeIn()
			$message.find('.shift').slideUp()
			$message.find('.if-accepted').slideDown()
			delay 3000, ->
				$message.slideUp ->
					$(@).remove()
			id = $message.data 'id'
			$('.notifications .friend-ask[data-id="' + id + '"]').each ->
				$(@).parents('li:first').remove()
			refreshPill()
			Ajax.post '/user/friend/accept', data: id: id
			cancel e
	]
	[
		'click'
		'.ignore-friend'
		($btn, e) ->
			$message = $btn.parents '.friend-ask'
			$message.slideUp ->
				$(@).remove()
			id = $message.data 'id'
			Ajax.post '/user/friend/ignore', data: id: id
			$('.notifications .friend-ask[data-id="' + id + '"]').each ->
				$(@).parents('li:first').remove()
			refreshPill()
			cancel e
	]
	[
		'click'
		'.notifications ul a'
		($a, e) ->
			unless $a.is('.friend-ask')
				$a.parents('li:first').remove()
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
			if href.length and Ajax.page href, true
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
	]

], ->
	params = @
	$document.on params[0], params[1], ->
		args = Array.prototype.slice.call arguments
		args.unshift $ @
		params[2].apply @, args
