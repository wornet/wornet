# No click delay with phone touch
if window.FastClick
	FastClick.attach document.body

do (s = textReplacements) ->
	# Default errors
	window.SERVER_ERROR_DEFAULT_MESSAGE = s("Perte de la connexion internet. La dernière action n'a pas pu être effectuée.")

	# Display a loading animation when page is loading
	window.onbeforeunload = (event) ->
		window._e = event
		# $.xhrPool.isWaiting() or
		somethingWaiting = do ->
			allEmpty = true
			$selection = $ '.do-not-loose'
			if window.$lastForm
				$selection = $selection.not window.$lastForm.find '.do-not-loose'
			$selection.each ->
				if $(@).val()
					allEmpty = false
					false
				else
					true
			! allEmpty
		if somethingWaiting
			return s("Attention, des modifications n'ont pas encore été sauvegardées.")
		else
			$.xhrPool.abortAll()
			showLoader()
		return

	$(window)
		.on "offline", ->
			$('.errors').warnings s("Attention, vous n'êtes plus connecté à Internet")
			return

		.on "online", ->
			$('.errors').infos s("Connexion Internet rétablie")
			return

	window.bootboxTexts ||= en: {}
	texts = bootboxTexts
	texts.en =
		OK: s("OK")
		CANCEL: s("Non")
		CONFIRM: s("Oui")
	window.confirmButtons = (callback) ->
		no:
			label: texts.en.CANCEL
		yes:
			label: texts.en.OK
			callback: callback
	return

# Convert titles attributes to tooltips when elements have a data-toggle="tooltip" atribute
$('[data-toggle="tooltip"]:not([data-original-title])').tooltip()

countLoaders = ->
	unless exists '.loading'
		$document.trigger 'end-of-load'

# Display loading animation until angular scope is ready
$('.loading').each ->
	$loading = $ @
	$loading.ready ->
		$scope = $loading.scope()
		$loading.removeClass 'loading'
		if $scope
			refreshScope $scope
			countLoaders()
		return
	return

countLoaders()

# Force the height of the elements (with data-ratio attribute) to keep the specified ratio
# And refresh each time the window is resized
onResize ->
	$('[data-ratio]').ratio()
	return
