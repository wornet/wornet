
checkDates = ->
	$('[data-date]').each ->
		$date = $(@)
		date = new Date $date.data 'date'
		$date.text date.humanDateTime()

setInterval checkDates, 5000
delay 1000, checkDates
