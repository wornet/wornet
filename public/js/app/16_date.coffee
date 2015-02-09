
checkDates = ->
	$('[data-date]').each ->
		$date = $ @
		unless exists $date.parents '.calendar'
			date = $date.date new Date "1970-01-01"
			if date > new Date "1971-01-01"
				$date.text date.humanDateTime()
		return
	return

setInterval checkDates, 5000
delay 1000, checkDates
