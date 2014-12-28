# No click delay with phone touch
if window.FastClick
	FastClick.attach document.body

do (s = textReplacements) ->
	# Default errors
	window.SERVER_ERROR_DEFAULT_MESSAGE = s("Perte de la connexion internet. La dernière action n'a pas pu être effectuée.")

	# Display a loading animation when page is loading
	window.onbeforeunload = ->
		$('.loader:last').css('z-index', 99999).removeClass 'preload'
		return

	$(window).on "offline", ->
		$('.errors').warnings s("Attention, vous n'êtes plus connecté à Internet")

	$(window).on "online", ->
		$('.errors').infos s("Connexion Internet rétablie")

	window.bootboxTexts ||= en: {}
	bootboxTexts.en =
		OK: s("Oui")
		CANCEL: s("Non")
		CONFIRM: s("Oui")
	window.confirmButtons = (callback) ->
		no:
			label: bootboxTexts.en.CANCEL
		yes:
			label: bootboxTexts.en.OK
			callback: callback
	return

# Convert titles attributes to tooltips when elements have a data-toggle="tooltip" atribute
$('[data-toggle="tooltip"]:not([data-original-title])').tooltip()

# Display loading animation until angular scope is ready
$('.loading').each ->
	$loading = $ @
	$loading.ready ->
		$scope = $loading.scope()
		$loading.removeClass 'loading'
		if $scope
			refreshScope $scope
		return
	return

# Force the height of the elements (with data-ratio attribute) to keep the specified ratio
# And refresh each time the window is resized
onResize ->
	$('[data-ratio]').ratio()
	return
