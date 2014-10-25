
checkDates = ->
	prevDate = null
	$('[data-date]').each ->
		$date = $(@)
		date = new Date $date.data 'date'
		unless date.isValid()
			date = new Date
		delayed = $date.data 'date-delay'
		if delayed and prevDate
			console.log [Math.abs(date.getTime() - prevDate.getTime()) / 1000, delayed]
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
