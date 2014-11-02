# Display a loading animation when page is loading
window.onbeforeunload = ->
	$('.loader:last').css('z-index', 99999).removeClass 'preload'
	return


# Convert titles attributes to tooltips when elements have a data-toggle="tooltip" atribute
$('[data-toggle="tooltip"]:not([data-original-title])').tooltip()


# Display loading animation until angular scope is ready
$ ->
	$('.loading').each ->
		$loadin = angular.element(@)
		$loadin.ready ->
			$scope = $loadin.scope()
			$loadin.removeClass 'loading'
			refreshScope $scope
			return
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
