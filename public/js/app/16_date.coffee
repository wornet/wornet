
checkDates = ->
	prevDate = null
	$('[data-date]').each ->
		$date = $ @
		unless exists $date.parents '.calendar'
			date = $date.date new Date
			delayed = $date.data 'date-delay'
			if delayed and prevDate and Math.abs(date.getTime() - prevDate.getTime()) / 1000 < delayed
				text = ''
			else
				text = date.humanDateTime()
			$date.text text
			prevDate = date
		return
	return

setInterval checkDates, 5000
delay 1000, checkDates
