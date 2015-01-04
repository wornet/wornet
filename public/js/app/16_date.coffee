
checkDates = ->
	$('[data-date]').each ->
		$date = $ @
		unless exists $date.parents '.calendar'
			date = $date.date new Date
			$date.text date.humanDateTime()
		return
	return

setInterval checkDates, 5000
delay 1000, checkDates
