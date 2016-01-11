
checkDates = ->
	$('[data-date]').each ->
		$date = $ @
		inPhrase = !!$date.data("phrase")
		unless exists $date.parents '.calendar'
			date = $date.date new Date "1970-01-01"
			if date > new Date "1971-01-01"
				$date.html (if !inPhrase then '<i class="glyphicon glyphicon-time" /> ' else if date < new Date().yesterday().midnight() then 'le ' else '') + date.humanDateTime()
		return
	return

setInterval checkDates, 5000
delay 1000, checkDates
