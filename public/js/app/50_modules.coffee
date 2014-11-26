# Display a loading animation when page is loading
window.onbeforeunload = ->
	$('.loader:last').css('z-index', 99999).removeClass 'preload'
	return

$(window).on "offline", ->
	$('.errors').warningx s("Attention, vous n'êtes plus connecté à Internet")

$(window).on "online", ->
	$('.errors').infos s("Connexion Internet rétablie")

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
	$('[data-ratio]').each ->
		$block = $ @
		ratio = $block.data('ratio') * 1
		if ratio > 0
			$block.height $block.width() / ratio
		return
	return
