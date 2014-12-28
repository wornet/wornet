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
			if exists $thumb
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
				$img = $ 'img', $iframe.prop 'contentWindow'
			if $img.length && $img[0].width > 0
				$form.find('img.upload-thumb').thumbSrc $img.prop 'src', src
			else
				$('.errors').errors $form.find('input.upload').data 'error'
			return
	]
	[
		'click'
		'[data-view-src], [data-view]'
		($img) ->
			loadMedia 'image',
				src: $img.data('view-src') || $img.prop('src')
				name: $img.data('view-name') || $img.prop('alt')
			return
	]
	[
		'submit'
		'#profile-photo'
		($form, e) ->
			enable = (enabled = true) ->
				$form.find('input[type="submit"]').prop 'disabled', ! enabled
			enable false
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
					enable()
					$form.find('input[type="submit"]').prop 'disabled', true
					$newImg = $(@responseText
						.replace /[\n\r\t]/g, ''
						.replace /^.*<body[^>]*>/ig, ''
						.replace /<\/body>.*$/ig, ''
					)
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

				xhr.send formData
				false
			else
				true
	]
	[
		'submit'
		'.status-images'
		($form, e) ->
			enable = (enabled = true) ->
				$form.find('input[type="submit"]').prop 'disabled', ! enabled
			enable false
			if typeof(FormData) is 'function'
				prevent e
				$scope = $form.scope()
				$container = $form.find '.upload-container'
				saveHtml = $container.html()
				$label = $container.find '.upload-label'
				$input = $container.find 'input[type="file"]'
				$input.hide()
				$progress = $('<div class="progress-bar"></div>').prependTo $container
				formData = new FormData()
				$.each $form.find('input[type="file"]')[0].files, (index) ->
					formData.append 'images[' + index + ']', @
					return
				formData.append 'album', $scope.currentAlbum._id || "new"
				formData.append '_csrf', $('head meta[name="_csrf"]').attr('content')

				xhr = new XMLHttpRequest()
				xhr.open 'POST', $form.prop('action'), true

				complete = ->
					enable()
					delay 1000, ->
						$container.html saveHtml
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
					$('<div>' + @responseText
						.replace /[\n\r\t]/g, ''
						.replace /^.*<body[^>]*>/ig, ''
						.replace /<\/body>.*$/ig, ''
					+ '</div>').find('.error, img').each ->
						$tag = $ @
						if $tag.is '.error'
							$('.errors').errors $tag.html()
						else
							$scope.medias.images.push
								src: $tag.prop 'src'
								name: $tag.prop 'alt'
						return
					$scope.$apply()
					return

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
		'click'
		'a.dropdown-toggle'
		($a, e) ->
			$dropdown = $a.next('ul.dropdown-menu')
			if $dropdown.find('li').length is 0 and $dropdown.is(':visible')
				$dropdown.toggle()
			return
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
		'.accept-friend, .ignore-friend'
		($btn, e) ->
			$message = $btn.parents '.friend-ask'
			id = $message.data 'id'
			if $btn.is '.accept-friend'
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
		'click'
		'.profile-edit-btn'
		($a, e) ->
			$('.profile-display').toggle()
			$('.profile-edit').toggleClass 'hidden'
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
	[
		'load'
		'iframe[data-ratio]'
		($iframe) ->
			$iframe.ratio()
			return
	]
	[
		'click'
		'[data-load-media]'
		($btn) ->
			params = $btn.data 'load-media'
			loadMedia.apply @, params
	]
	[
		'click'
		'.open-shutter'
		($a, e) ->
			$('#navbar, #wrap, #shutter').toggleClass 'opened-shutter'
			Ajax.post '/user/shutter/' + (if $('#shutter').is '.opened-shutter' then 'open' else 'close')
			delay 200, ->
				$a.blur()
				return
			cancel e
	]
	[
		'click'
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
		'click'
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

], ->
	params = @
	$document.on params[0], params[1], ->
		args = Array.prototype.slice.call arguments
		args.unshift $ @
		params[2].apply @, args
	return
