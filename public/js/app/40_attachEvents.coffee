# Handle touch events

loadIFrameEvents = []

do ->

	syncShutter = ($a) ->
		Ajax.post '/user/shutter/' + (if $('#shutter').is '.opened-shutter' then 'open' else 'close')
		delay 200, ->
			if $a
				$a.blur()
			return
	# events to recognize as a click
	click = 'touchtap click'
	# attribute to trigger the delayed source feature
	delayedSrcAttr = 'delayed-src'

	# variables for touch, tap and swipe handle
	touchTarget = null
	isTouchEvent = false
	touch = 0
	x = 0
	y = 0
	_x = 0
	_y = 0

	pointer = (e) ->
		if t = (e.originalEvent and e.originalEvent.targetTouches)
			t[0]
		else
			e

	scrollTop = $document.scrollTop()

	$underbar = $('#underbar')

	$document

	.on 'touchstart mousedown', (e) ->
		p = pointer e
		_x = x = p.pageX
		_y = y = p.pageY - $document.scrollTop()
		touch = $.now()
		touchTarget = e.target
		return

	.on 'touchend mouseup touchcancel', (e) ->
		dx = x - _x
		dy = y - _y
		ax = Math.abs dx
		ay = Math.abs dy
		isTouchEvent = 0 is (e.type + '').indexOf 'touch'
		if ax > 50 or ay > 50
			$(touchTarget)
				.trigger 'swipe', [dx, dy, isTouchEvent]
				.trigger if ax > ay
					if dx > 0
						'swiperight'
					else
						'swipeleft'
				else
					if dy > 0
						'swipedown'
					else
						'swipeup'
				, [isTouchEvent]
		else if ax < 4 and ay < 4 and $.now() - touch <= 200
			$(touchTarget)
				.trigger 'tap'
				.trigger if e.type is 'touchstart'
					'touchtap'
				else
					'mousetap'
		touch = 0
		return

	.on 'touchmove mousemove', (e) ->
		p = pointer e
		x = p.pageX
		y = p.pageY
		if touch
			$(e.target).trigger 'swipemouve', [x - _x, y - _y]
		return

	.on 'end-of-load', ->
		if id = getSessionItem 'readNotification'
			readNotification id
			removeSessionItem 'readNotification'
		$('img[data-' + delayedSrcAttr + ']').each ->
			$img = $ @
			$img.attr 'src', $img.data delayedSrcAttr
			$img.on 'error', ->
				$img.parent().parent().remove()
				return
			$img.on 'load', ->
				$img.parents('.fade-on-load:first').removeClass 'not-loaded'
				return
			$img.removeAttr delayedSrcAttr
			return
		return

	.on 'swiperight', (e, isTouchEvent) ->
		if isTouchEvent and exists '#shutter'
			$('.wornet-navbar, #wrap, #shutter').removeClass 'opened-shutter'
			$('#directives-calendar > .well').removeClass 'col-xs-9'
			syncShutter()
			cancel e
		else
			true

	.on 'swipeleft', (e, isTouchEvent) ->
		if isTouchEvent and exists '#shutter'
			$('.wornet-navbar, #wrap, #shutter').addClass 'opened-shutter'
			$('#directives-calendar > .well').addClass 'col-xs-9'
			syncShutter()
			cancel e
		else
			true

	# Start of issue #232
	# .scroll (e) ->
	# 	$document.trigger if scrollTop < $document.scrollTop()
	# 		'scrolldown'
	# 	else
	# 		'scrollup'
	# 	scrollTop = $document.scrollTop()
	#
	# .on 'scrolldown', ->
	# 	$underbar.addClass('flattened')
	#
	# .on 'scrollup', ->
	# 	$underbar.removeClass('flattened')
	#
	# .one 'scrollup', ->
	# 	$underbar
	# 		.addClass('flattenable')
	# 		.detach()
	# 		.appendTo($('#navbar'))

	.keydown (e) ->
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

	# Track on tap
	.on click, '*', trackEvent

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
			'keyup focus change tap'
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
			'tap'
			'[data-view-src]'
			($img) ->
				loadMedia 'image',
					src: $img.data('view-src') || $img.prop('src')
					name: $img.data('view-name') || $img.prop('alt')
				return
		]
		[
			'touchtap'
			'.photos-thumbs a[href][data-toggle="tooltip"]'
			($a, e) ->
				locationHref $a.attr 'href'
				cancel e
		]
		[
			'error'
			'#profile-photo, #profile-photo-media'
			($form, e, error) ->
				$form.find('input[type="submit"]').prop 'disabled', false
				$loader = $form.find '.loader'
				$loader.fadeOut 'fast', $loader.remove
				$('.errors').errors error
		]
		[
			'upload'
			'#profile-photo, #profile-photo-media'
			($form, e, body) ->
				$form.find('input[type="submit"]').prop 'disabled', false
				$img = $form.find 'img.upload-thumb'
				$newImg = $(body
					.replace /[\n\r\t]/g, ''
					.replace /^.*<body[^>]*>/ig, ''
					.replace /<\/body>.*$/ig, ''
				)
				if $newImg.find('h3').length
					$form.trigger 'error', [$newImg.find('h3 + p').text()]
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
							albums = (objectResolve getSessionValue albumKey()) || []
							present = false
							for a in albums
								if a._id is album._id
									present = true
									break
							unless present
								albums.push album
								statusScope.albums = albums
								setSessionValue albumKey(), albums
								refreshScope statusScope
							getAlbumsFromServer (err, albums, nbAlbums, user) ->
								$('#add-profile-photo').hide()
								setMediaAlbums albums
								refreshScope statusScope
								return
						$img.fadeOut 'fast', ->
							$loader = $form.find '.loader'
							$loader.fadeOut 'fast', $loader.remove
							$img.thumbSrc(newSource).fadeIn 'fast'

							return
					else
						$form.trigger 'error', [$newImg.text()]
				return
		]
		[
			'submit'
			'#profile-photo, #profile-photo-media'
			($form, e) ->
				$form.find('input[type="submit"]').prop 'disabled', true
				$img = $form.find 'img.upload-thumb'
				$img.fadeOut('fast')
				withFormData $form, (formData, xhr) ->
					$progress = $form.find '.progress-radial'
					prevent e
					file = $form.find('input[type="file"]')[0].files[0]
					formData.append 'photo', file

					mediaFlag = $form.find('input[name="mediaFlag"]:first')
					if mediaFlag
						formData.append 'mediaFlag', mediaFlag.val()

					formData.append '_csrf', $('head meta[name="_csrf"]').attr('content')

					xhr.open 'POST', $form.prop('action'), true

					xhr.upload.onprogress = (e) ->
						if e.lengthComputable
							$progress.circularProgress e.loaded / e.total
						return

					xhr.onerror = ->
						$error = $ @responseText
						unless $error.is '.error'
							$error = $error.find '.error'
						$error = $error.filter '.error'
						$form.trigger 'error', [$error.html()]
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
				$html = $('<div>' + body
					.replace /[\n\r\t]/g, ''
					.replace /^.*<body[^>]*>/ig, ''
					.replace /<\/body>.*$/ig, ''
				+ '</div>')
				if $html.find('h3').length
					$('.errors').errors $html.find('h3 + p').text()
				else
					$html.find('.error, img').each ->
						$tag = $ @
						if $tag.is '.error'
							$('.errors').errors $tag.html()
						else
							$scope.medias.images.push
								id: idFromUrl $tag.prop 'src'
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
					$('.publish input').prop 'disabled', ! enabled
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
							$label
								.css "font-size": "30px"
								.css "margin-top": "20px"
								.text percent
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
			'tap'
			'[data-toggle="lightbox"]'
			($btn, e) ->
				$btn.ekkoLightbox()
				prevent e
		]
		[
			'tap'
			'a.dropdown-toggle'
			($a, e) ->
				$dropdown = $a.next 'ul.dropdown-menu'
				if $dropdown.find('li').length is 0 and $dropdown.is ':visible'
					$dropdown.toggle()
				return
		]
		[
			'touchtap',
			'[ng-click]'
			($a, e) ->
				$a.click()
				e.preventDefault()
				return
		]
		[
			'touchtap',
			'img'
			($img, e) ->
				unless exists $img.parents 'a, button'
					e.preventDefault()
				return
		]
		[
			click
			'[data-ajax], [ng-attr-data-ajax]'
			($btn) ->
				params = ($btn.attr 'data-ajax') || []
				if '' + params is params
					params = [params]
				method = params[0] || 'get'
				url = params[1] || $btn.attr 'href'
				data = params[2] || {}
				Ajax[method] url, data
				return
		]
		[
			click
			'[data-click], [ng-attr-data-click]'
			($btn) ->
				i = 0
				params = while typeof (param = $btn.attr("data-param" + (i++))) isnt "undefined"
					param
				$target = $ $btn.attr 'data-target'
				$target[$btn.attr 'data-click'].apply $target, params
				return
		]
		[
			click
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
								if ok and ! $('[data-id="' + id + '"]').parents('.friend-ask').find('.accept-friend').eq(0).click().length
									# To fix: id is a user hashed id and not the friend id as expected from the friend controller
									Ajax.post '/user/friend/accept', data: id: id
						else
							$('.remove-friend-ask').show()
							$('.add-friend-ask').hide()
							$btn.hide()
				prevent e
		]
		[
			click
			'[data-remove-friend-ask], [ng-attr-data-remove-friend-ask]'
			($btn, e) ->
				id = $btn.data 'remove-friend-ask'
				Ajax.delete '/user/friend/pending',
					data: userId: id
					success: (data) ->
						$('.remove-friend-ask').hide()
						$('.add-friend-ask').show()
						$btn.hide()
				prevent e
		]
		[
			click
			'[data-follow]'
			($btn, e) ->
				id = $btn.data 'follow'
				Ajax.put '/user/profile/follow',
					data: hashedId: id
					success: (data) ->
						$('.follow').hide()
						$('.unfollow').show()
						$btn.hide()
						$('.search-unfollow[data-unfollow="' + id + '"]').removeClass("ng-hide").show()
				prevent e
		]
		[
			click
			'[data-unfollow]'
			($btn, e) ->
				id = $btn.data 'unfollow'
				Ajax.delete '/user/profile/follow',
					data: hashedId: id
					success: (data) ->
						$('.follow').show()
						$('.unfollow').hide()
						$btn.hide()
						$('.search-follow[data-follow="' + id + '"]').removeClass("ng-hide").show()
				prevent e
		]
		[
			click
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
						locationHref '/user/friend/accept/' + id + '?goingTo=' + encodeURIComponent userUrl
					else
						$friends = $ '#friends'
						if exists($friends) and ! exists($friends.find('[data-id="' + userId + '"]'))
							$li = $('<li>').appendTo $friends
							$a = $message.find 'a'
							if exists $a
								$a.clone(true).appendTo($li).fadeOut(0).fadeIn()
							else if exists($img) and $img.width() is 50
								$a = $ '<a>'
								$a.attr 'href', userUrl
								$img.clone(true).appendTo $a
								$a.appendTo($li).fadeOut(0).fadeIn()
							numberOfFriends = $friends.find('li').length
							s = textReplacements
							text = s("({number} ami)|({number} amis)", { number: numberOfFriends }, numberOfFriends)
							$('.numberOfFriends').text text
						# $message.find('.if-accepted').slideDown()
						# delay 3000, ->
						# 	$message.slideUp ->
						# 		$(@).remove()
						# 		return
						# 	return
						Ajax.post '/user/friend/accept', data: id: id
				else
					Ajax.post '/user/friend/ignore', data: id: id
				$message.slideUp ->
					$(@).remove()
					deleteFriendAsk id
					return
				refreshPill()
				cancel e
		]
		[
			click + " mousedown"
			'.notifications ul a:not(".activities, .read-all-notifs"), .notifications-mobile ul a:not(".activities, .read-all-notifs"), #notification-list a'
			($a, e) ->
				href = $a.find('[data-href]').data 'href'
				id = $a.parents('li:first').attr 'data-id'
				if href
					if id
						setSessionItem 'readNotification', id
					delay 1, ->
						#clic whith mouse wheel
						if e.type is "mousedown" and e.which is 2
							window.open href, '_blank'
						else if e.which is 3
							$a.find('[data-href]').attr('data-href', href)
							$a[0].href = href
							cancel e
						else
							locationHref href
							hash = href.replace /^[^#]+#/g, ''
							if hash and hash isnt href
								$block = $ '#' + hash + ', [data-id=' + hash + ']'
								if exists $block
									$document.scrollTop $block.offset().top - 68
				delay 2, refreshPill
				if id
					readNotification id
				if $a.is '.friend-accepted'
					true
				else
					cancel e
		]
		[
			click
			'a[href][target!="_blank"]'
			($a, e) ->
				if $a.is '.ajax'
					cancel e
				else
					href = $a.prop('href')
						.replace /#.*$/g, ''
						.replace /^https?:\/\/[^\/]+/g, ''
					if href is '/user/logout'
						removeSessionItems()
					if window.location.pathname is href
						window.location.reload()
					else if navigator.standalone
						window.location = href
						cancel e
					else
						true
				###
				if href.length and href.charAt(0) isnt '#' and Ajax.page href, true
					cancel e
				else
					true
				###
		]
		[
			click
			'.profile-edit-btn'
			($a, e) ->
				$('.profile-display').toggle()
				$('.profile-edit').toggleClass 'hidden'
				cancel e
		]
		[
			'load'
			'iframe[data-ratio]'
			($iframe) ->
				$iframe.ratio()
				return
		]
		[
			'tap'
			'[data-load-media]'
			($btn) ->
				params = $btn.data 'load-media'
				loadMedia.apply @, params
		]
		[
			click
			'li.open-shutter a'
			($a, e) ->
				$('.wornet-navbar, #wrap, #shutter').toggleClass 'opened-shutter'
				$('#directives-calendar > .well').toggleClass 'col-xs-9'
				syncShutter $a
				cancel e
		]
		[
			click
			'.footer a:not(.legals, .contact)'
			($a, e) ->
				window.open $a.attr 'href'
				cancel e
		]
		[
			click
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
									removeSessionItems()
									locationHref data.goingTo
								return
						return
				delay 600, ->
					$('#delete-account-password').focus()
					return
				cancel e
		]
		[
			click
			'[data-delete]'
			($a, e) ->
				bootbox.confirm $a.data('message'), (ok) ->
					if ok
						if clearStorage = $a.data 'clear-storage'
							if clearStorage is '*'
								removeSessionItems()
							else
								removeSessionItem clearStorage
						Ajax.delete ($a.data('delete') || location.href), (data) ->
							getAlbumsFromServer (err, albums) ->
								return
							if data.goingTo
								locationHref data.goingTo
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
			click
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
					s("Caractères restants : {remains}", remains: max - val.length) +
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
		[
			'swipeleft'
			'[ng-controller="MediaViewerCtrl"]'
			($ctrl) ->
				$ctrl.find('.next:visible:last').not('.disabled').click()
		]
		[
			'swiperight'
			'[ng-controller="MediaViewerCtrl"]'
			($ctrl) ->
				$ctrl.find('.prev:visible:last').not('.disabled').click()
		]
		[
			'updatePoints'
			'.points'
			($span, e, status, adding) ->
				if status and status.author
					if getData('at') is getData('me') and status.author.hashedId is getData('me')
						s = textReplacements
						points = 1 #simple status
						if status.images and status.images.length > 0
							points = 2 #status with photo
						if status.videos and status.videos.length > 0
							points = 3 if points is 1 #status with video but without photo
							points = 4 if points is 2 #status with video and photo

						newPoints = parseInt($('.points b').html()) + if adding
							(points * parseInt(getData 'numberOfFriends'))
						else
							- (status.pointsValue || 0)
						if newPoints < 0
							newPoints = 0
						$('.points').html s("{points} point|{points} points", { points: '<b>' + newPoints + '</b>' }, newPoints)
		]
		[
			'focus'
			'.chat textarea'
			($field, e) ->
				idUsers = []
				$field.closest('.chat').find('.users').each (key, val) ->
					idUsers.push $(val).data('hashed-id')
				$('title').html('Wornet')
				chatService.updateNewMessages idUsers, 0
		]
		[
			'tap'
			'.open-chat-list'
			($span, e) ->
				Ajax.get '/user/chat/list', (chat) ->
					chatListScope.chatList = chat.chatList
					refreshScope chatListScope
		]
		[
			'change'
			'#account-confidentiality'
			($select, e) ->
				privateFields = ['.account-confidentiality-hint-private', '.confidentialityFollowList' ]
				publicFields = ['.account-confidentiality-hint-public', '#allowFriendPostOnMe', '#urlIdDisponibility', '#urlIdContainer', '.certification-link']
				if $select.val() is "private"
					for field in privateFields
						$(field).removeClass("hidden")
					for field in publicFields
						$(field).addClass("hidden")
				else
					for field in privateFields
						$(field).addClass("hidden")
					for field in publicFields
						$(field).removeClass("hidden")

		]
		[
			'submit'
			'#certification-form'
			($form, e) ->
				s = textReplacements
				$scope = $form.scope()
				formData = new FormData()
				certification = $scope.certification
				if $('input[name="proof"]')[0].files.length
					certification.proof = $('input[name="proof"]')[0].files[0]
				switch $scope.certification.userType
					when "particular"
						requiredFields =
							userType: 'Type'
							firstName: 'Prénom'
							lastName: 'Nom'
							email: 'Email'
							telephone: 'Téléphone'
							proof: 'Justificatif'
					when "business", "association"
						requiredFields =
							userType: 'Type'
							entrepriseName: "Nom de l'entreprise"
							firstName: 'Prénom'
							lastName: 'Nom'
							email: 'Email'
							telephone: 'Téléphone'
							proof: 'Justificatif'

				missingFields = []
				for fieldToTest, userError of requiredFields
					if !certification[fieldToTest]
						missingFields.push userError


				if missingFields.length
					$('#certification-error')
						.html s("Veuillez renseigner les champs suivants : ") + missingFields.join ', '
						.show()
				else
					withFormData (formData, xhr) ->
						prevent e
						for key, val of certification
							formData.append key, val
						formData.append '_csrf', $('head meta[name="_csrf"]').attr('content')
						xhr.open 'POST', $form.prop('action'), true
						xhr.onload = ->
							toastr.success s("Votre demande de certification a bien été envoyée. Merci !"), s "C'est fait"
							$('#certification [data-dismiss="modal"]:first').click()
							$('.certification-link').hide()
							$scope.initModal()
		]
	], ->
		params = @
		if @[0] is 'load'
			loadIFrameEvents.push [@[1], @[2]]
		else
			# evts = params[0].split /\s/g
			$document.on params[0], params[1],  ->
				args = Array.prototype.slice.call arguments
				args.unshift $ @
				params[2].apply @, args
			return

		return

	return
