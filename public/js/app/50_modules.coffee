# Display a loading animation when page is loading
window.onbeforeunload = ->
	$('.loader:last').css('z-index', 99999).removeClass 'preload'
	null


# Convert titles attributes to tooltips when elements have a data-toggle="tooltip" atribute
$('[data-toggle="tooltip"]').tooltip()


# Force the height of the elements (with data-ratio attribute) to keep the specified ratio
# And refresh each time the window is resized
onResize ->
	$('[data-ratio]').each ->
		$block = $ @
		ratio = $block.data('ratio') * 1
		if ratio > 0
			$block.height $block.width() / ratio
