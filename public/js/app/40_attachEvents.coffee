# All global events
# [ [ "events to catch", "selector to target", callbackFunction ], ... ]

loadIFrameEvents = []

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
		'keyup focus change click touchstart'
		'.check-pass'
		($field) ->
			$password = $field.find 'input[type="password"]'
			$security = $field.find('.pass-security').removeClass 'verylow low medium high veryhigh'
			strongness = passwordStrongness $password.val()
			$security.addClass switch
				when strongness > 10000000000000000
					'veryhigh'
				when strongness > 10000000000000
					'high'
				when strongness > 1000000000
					'medium'
				when strongness > 1000000
					'low'
				else
					'verylow'
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
			if exists $thumb
				$('<div class="loader"></div>').appendTo($parent).fadeOut(0).fadeIn 'fast'
			$input.parents('form').submit()
			return
	]
	[
		'load'
		'iframe[name$="upload"]'
		($iframe) ->
			name = $iframe.attr 'name'
			$form = $ 'form[target="' + name + '"]'
			$img = []
			$loader = $form.find '.loader'
			$loader.fadeOut 'fast', $loader.remove
			if $form.length
				w = $iframe.prop 'contentWindow'
				if w and w.document and w.document.body
					body = w.document.body.innerHTML
			if body
				$form.trigger 'upload', [body]
			else
				$('.errors').errors $form.find('input.upload').data 'error'
			return
	]
	[
		'click touchstart'
		'[data-view-src]'
		($img) ->
			loadMedia 'image',
				src: $img.data('view-src') || $img.prop('src')
				name: $img.data('view-name') || $img.prop('alt')
			return
	]
	[
		'touchstart'
		'.photos-thumbs a[href][data-toggle="tooltip"]'
		($a, e) ->
			location.href = $a.attr 'href'
			cancel e
	]
	[
		'upload'
		'#profile-photo'
		($form, e, body) ->
			$form.find('input[type="submit"]').prop 'disabled', false
			$img = $form.find 'img.upload-thumb'
			$newImg = $(body
				.replace /[\n\r\t]/g, ''
				.replace /^.*<body[^>]*>/ig, ''
				.replace /<\/body>.*$/ig, ''
			)
			if $newImg.find('h3').length
				@onerror()
			else
				unless $newImg.is('.error') or $newImg.is('img')
					$newImg = $newImg.find 'img'
				if $newImg.is('img')
					newSource = $newImg.prop 'src'
					regExp = /\/photo\/[0-9]+x([^\/\.]+)[\/\.]/g
					match = newSource.match regExp
					if match
						id = match[0].replace regExp, '$1'
						$('#uploadedPhotoId').val id
					album = $newImg.data 'created-album'
					if album
						albums = objectResolve JSON.parse sessionStorage.albums
						present = false
						for a in albums
							if a._id is album._id
								present = true
								break
						unless present
							albums.push album
							statusScope.albums = albums
							sessionStorage.albums = JSON.stringify albums
							refreshScope statusScope
						getAlbumsFromServer ->
							refreshScope statusScope
							return
					$img.fadeOut 'fast', ->
						$loader = $form.find '.loader'
						$loader.fadeOut 'fast', $loader.remove
						$img.thumbSrc(newSource).fadeIn 'fast'
						return
				else
					@onerror()
			return
	]
	[
		'submit'
		'#profile-photo'
		($form, e) ->
			$form.find('input[type="submit"]').prop 'disabled', true
			$img = $form.find 'img.upload-thumb'
			$img.fadeOut('fast')
			withFormData $form, (formData, xhr) ->
				$progress = $form.find '.progress-radial'
				prevent e
				file = $form.find('input[type="file"]')[0].files[0]
				formData.append 'photo', file
				formData.append '_csrf', $('head meta[name="_csrf"]').attr('content')

				xhr.open 'POST', $form.prop('action'), true

				xhr.upload.onprogress = (e) ->
					if e.lengthComputable
						$progress.circularProgress e.loaded / e.total
					return

				xhr.onerror = ->
					enable()
					$error = $ @responseText
					unless $error.is '.error'
						$error = $error.find '.error'
					$error = $error.filter '.error'
					$loader = $form.find '.loader'
					$loader.fadeOut 'fast', $loader.remove
					$('.errors').errors $error.html()
					return

				xhr.onload = ->
					$form.trigger 'upload', [@responseText]
					return
				return
	]
	[
		'upload'
		'.status-images'
		($form, e, body) ->
			$form.find('input[type="submit"]').prop 'disabled', false
			$container = $form.find '.upload-container'
			$container.html $container.data 'save-html'
			$scope = $form.scope()
			$html = $ '<div>' + body
				.replace /[\n\r\t]/g, ''
				.replace /^.*<body[^>]*>/ig, ''
				.replace /<\/body>.*$/ig, ''
			+ '</div>'
			if $html.find('h3').length
				$('.errors').errors $html.find('h3 + p')
			else
				$html.find('.error, img').each ->
					$tag = $ @
					if $tag.is '.error'
						$('.errors').errors $tag.html()
					else
						$scope.medias.images.push
							src: $tag.prop 'src'
							name: $tag.prop 'alt'
					return
			$scope.$apply()
	]
	[
		'submit'
		'.status-images'
		($form, e) ->
			enable = (enabled = true) ->
				$form.find('input[type="submit"]').prop 'disabled', ! enabled
			enable false
			$container = $form.find '.upload-container'
			$container.data 'save-html', $container.html()
			withFormData $form, (formData, xhr) ->
				prevent e
				$scope = $form.scope()
				$label = $container.find '.upload-label'
				$input = $container.find 'input[type="file"]'
				$input.hide()
				$progress = $('<div class="progress-bar"></div>').prependTo $container
				$.each $form.find('input[type="file"]')[0].files, (index) ->
					formData.append 'photo', @
					return
				formData.append 'album', $scope.currentAlbum._id || "new"
				formData.append '_csrf', $('head meta[name="_csrf"]').attr('content')

				xhr.open 'POST', $form.prop('action'), true

				complete = ->
					enable()
					delay 1000, ->
						$input.show()

				xhr.upload.onprogress = (e) ->
					if e.lengthComputable
						percent = Math.round(e.loaded * 100 / e.total) + '%'
						$progress.css width: percent
						$label.text percent
					return

				xhr.onerror = ->
					complete()
					$('.errors').errors $('<div>' + @responseText + '</div>').find('.error').html()
					return

				xhr.onload = ->
					complete()
					$form.trigger 'upload', [@responseText]
					return
				return
	]
	[
		'click touchstart'
		'[data-toggle="lightbox"]'
		($btn, e) ->
			$btn.ekkoLightbox()
			prevent e
	]
	[
		'click touchstart'
		'a.dropdown-toggle'
		($a, e) ->
			$dropdown = $a.next('ul.dropdown-menu')
			if $dropdown.find('li').length is 0 and $dropdown.is(':visible')
				$dropdown.toggle()
			return
	]
	[
		'touchstart',
		'[ng-click]'
		($a, e) ->
			$a.click()
			e.preventDefault()
			return
	]
	[
		'touchstart',
		'img'
		($img, e) ->
			unless exists $img.parents 'a, button'
				e.preventDefault()
			return
	]
	[
		'click touchstart'
		'[data-click], [ng-attr-data-click]'
		($btn) ->
			i = 0
			params = while typeof (param = $btn.data("param" + (i++))) isnt "undefined"
				param
			$target = $ $btn.data 'target'
			$target[$btn.data 'click'].apply $target, params
			return
	]
	[
		'click touchstart'
		'[data-ask-for-friend], [ng-attr-data-ask-for-friend]'
		($btn, e) ->
			s = textReplacements
			name = decodeURIComponent $btn.attr('href').replace(/^.*\/([^\/]+)$/g, '$1')
			id = $btn.data 'ask-for-friend'
			Ajax.post '/user/friend',
				data: userId: id
				success: (data) ->
					if data.exists
						bootbox.confirm s("{name} vous a déjà demandé en ami, voulez-vous accepter sa demande maintenant ?", name: name), (ok) ->
							if ok
								$accept = $ '.friend-ask[data-id="' + id + '"] .accept-friend'
								if exists $accept
									$accept.click()
								else
									Ajax.post '/user/friend/accept', data: id: id
			if $btn.is '.destroyable'
				$btn.fadeOut ->
					$btn.remove()
			prevent e
	]
	[
		'click touchstart'
		'.accept-friend, .ignore-friend'
		($btn, e) ->
			$message = $btn.parents '.friend-ask'
			id = $message.data 'id'
			$img = $message.find 'img'
			if exists $img
				userId = $img.data 'id'
				userUrl = '/user/profile/' + userId+ '/' + encodeURIComponent $img.prop 'alt'
			if $btn.is '.accept-friend'
				if userId and userId is getData 'at'
					location.href = '/user/friend/accept/' + id + '?goingTo=' + encodeURIComponent userUrl
				else
					$friends = $ '#friends'
					if exists $friends
						$li = $('<li>').appendTo $friends
						$a = $message.find 'a'
						if exists $a
							$a.clone(true).appendTo($li).fadeOut(0).fadeIn()
						else if exists $img
							$a = $ '<a>'
							$a.attr 'href', userUrl
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
					Ajax.post '/user/friend/accept', data: id: id
			else
				Ajax.post '/user/friend/ignore', data: id: id
				$message.slideUp ->
					$(@).remove()
					return
			deleteFriendAsk id
			refreshPill()
			cancel e
	]
	# [
	# 	'click touchstart'
	# 	'.notifications a.dropdown-toggle'
	# 	($a, e) ->
	# 		if sessionStorage
	# 			notifications = ''
	# 			$a.parent().find('ul.dropdown-menu li').each ->
	# 				notifications += notificationPrint @
	# 				return
	# 			sessionStorage.sawNotifications = notifications
	# 			refreshPill()
	# 		return
	# ]
	[
		'click touchstart'
		'.notifications ul a'
		($a, e) ->
			href = $a.find('[data-href]').data 'href'
			if href
				delay 1, ->
					location.href = href
			unless $a.is '[data-id]'
				dateId = $a.dateId()
				if dateId
					Ajax.get '/user/notify/read/' + dateId, (data) ->
						notificationsService.setNotifications notifications
			if $a.is '.friend-accepted'
				true
			else
				unless $a.is '.friend-ask'
					notifications = sessionStorage.sawNotifications || ''
					$a.parents('li:first').each ->
						print = notificationPrint @
						if -1 is notifications.indexOf print
							notifications += print
						return
					sessionStorage.sawNotifications = notifications
					# $a.parents('li:first').remove()
					refreshPill()
				cancel e
	]
	[
		'click touchstart'
		'a[href][target!="_blank"]'
		($a, e) ->
			if $a.is '.ajax'
				cancel e
			else
				href = $a.prop('href')
					.replace /#.*$/g, ''
					.replace /^https?:\/\/[^\/]+/g, ''
				if href is '/user/logout' and window.sessionStorage
					sessionStorage.clear()
				true
			###
			if href.length and href.charAt(0) isnt '#' and Ajax.page href, true
				cancel e
			else
				true
			###
	]
	[
		'click touchstart'
		'.profile-edit-btn'
		($a, e) ->
			$('.profile-display').toggle()
			$('.profile-edit').toggleClass 'hidden'
			cancel e
	]
	[
		'click touchstart'
		'[give-focus]'
		($a) ->
			sel = $a.attr 'give-focus'
			delay 1, ->
				$(sel).focus()
				return
			return
	]
	[
		'load'
		'iframe[data-ratio]'
		($iframe) ->
			$iframe.ratio()
			return
	]
	[
		'click touchstart'
		'[data-load-media]'
		($btn) ->
			params = $btn.data 'load-media'
			loadMedia.apply @, params
	]
	[
		'click touchstart'
		'li.open-shutter a'
		($a, e) ->
			$('#navbar, #wrap, #shutter').toggleClass 'opened-shutter'
			$('#directives-calendar > .well').toggleClass 'col-xs-9'
			Ajax.post '/user/shutter/' + (if $('#shutter').is '.opened-shutter' then 'open' else 'close')
			delay 200, ->
				$a.blur()
				return
			cancel e
	]
	[
		'click touchstart'
		'#delete-account'
		($a, e) ->
			bootbox.dialog
				message: '<label>' + $a.data('message') + "<br><input type='password' id='delete-account-password' required autofocus></label>"
				title: $a.data 'title'
				buttons: confirmButtons ->
					Ajax.delete '/user',
						data: password: $('#delete-account-password').val()
						success: (data) ->
							if data.goingTo
								if window.sessionStorage
									sessionStorage.clear()
								location.href = data.goingTo
							return
					return
			delay 600, ->
				$('#delete-account-password').focus()
				return
			cancel e
	]
	[
		'click touchstart'
		'[data-delete]'
		($a, e) ->
			bootbox.confirm $a.data('message'), (ok) ->
				if ok
					if window.sessionStorage
						clearStorage = $a.data 'clear-storage'
						if clearStorage
							if clearStorage is '*'
								sessionStorage.clear()
							else
								delete sessionStorage[clearStorage]
					Ajax.delete ($a.data('delete') || location.href), (data) ->
						if data.goingTo
							location.href = data.goingTo
						target = $a.data 'slide-up'
						if target
							$(target).slideUp ->
								@remove()
								return
						target = $a.data 'fade-out'
						if target
							$(target).fadeOut ->
								@remove()
								return
						return
				return
			cancel e
	]
	[
		'click touchstart'
		'[data-click-alert]'
		($a, e) ->
			bootbox.alert $a.data 'click-alert'
			cancel e
	]
	[
		'keyup change'
		'.counter'
		($field) ->
			val = $field.val() || ''
			max = $field.prop 'maxlength'
			$('.static-tooltip').remove()
			if val and max
				s = textReplacements
				$field.before('<div class="static-tooltip"><div class="tooltip top"><div class="tooltip-arrow"></div><div class="tooltip-inner">' +
				s("Caractères restants : {remains}", { remains: max - val.length }) +
				'</div></div></div>')
			return
	]
	[
		'blur'
		'.counter'
		->
			$('.static-tooltip').remove()
			return
	]
	[
		'submit'
		'form'
		($form) ->
			window.$lastForm = $form
			delay 1000, ->
				delete window.$lastForm
				return
			return
	]

], ->
	params = @
	if @[0] is 'load'
		loadIFrameEvents.push [@[1], @[2]]
	else
		$document.on params[0], params[1],  ->
			args = Array.prototype.slice.call arguments
			args.unshift $ @
			params[2].apply @, args
		return


$document.keydown (e) ->
	switch e.which
		when 27 # Escape
			if $('[data-dismiss]:visible:last').not('.disabled').click().length
				return cancel e
		when 37 # Left arrow
			if $('.prev:visible:last').not('.disabled').click().length
				return cancel e
		when 39 # Right arrow
			if $('.next:visible:last').not('.disabled').click().length
				return cancel e
	return
