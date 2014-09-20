# Save user datas on submit
saveUser = ($scope) ->
	$scope.submit = (user) ->
		user.remember = $('[ng-model="user.remember"]').prop 'checked'
		sessionStorage['user'] = JSON.stringify user

# Resolve object get from template (passed in JSON)
# Restore date object converted to strings previously (by JSON stringification)
objectResolve = (value) ->

	key = 'resolvedCTBSWSydrqSuW2QyzUGMBTshU9SCJn5p'

	# First, convert the date and put the "resolved" key to do not reconvert
	enter = (value) ->
		switch typeof(value)
			when 'object'
				unless value[key]
					for v, i in value
						value[i] = enter value[i]
					value[key] = true
			when 'string'
				if /^[0-9-]+T[0-9:.]+Z$/.test value
					date = new Date value
					if `date != 'Invalid Date'`
						value = date
		value

	# Then, remove all the "resolved" keys
	leave = (value) ->
		if typeof(value) is 'object' and value[key]
			delete value[key]
			for v, i in value
				value[i] = leave value[i]
		value

	leave enter value


# To know if a object or selector exists
exists = (sel) ->
	!!$(sel).length


# Function to get a data passed throught the template
getData = (name) ->
	name = name.replace /(\\|")/g, '\\$1'
	$data = $ '[data-data][data-name="' + name + '"]'
	unless exists $data
		console.warn name + " data not found."
		console.trace()
	objectResolve $data.data 'value'


# Shorthand to exec a callback (second parameter) after a delay
# (fisrt parameter) specified in milliseconds
delay = (ms, cb) ->
	setTimeout cb, ms


# Return strongness level of a password
passwordStrongness = (mdp) ->

	#
	#	Les types de mot de passe sont classés du plus résistant au plus fragile.
	#	Un facteur est alors déterminé en fonction du nombre de possibilités à
	#	tester pour un robot et ce facteur est élevé à la puissance mdp.length
	#	correspondant au nombre de caractères à cracker.
	#	La fonction retourne donc une approximation très proche du nombre de tests
	#	que doit lancer une attaque de force brute pour essayer toutes les
	#	combinaisons pour un type de mot de passe donné.
	#
	#	*mono-casse : tout en majuscules ou tout en minuscules
	#

	switch
		# Mot de passe vide
		when mdp is ""
			0

		# Mot de passe numérique
		when mdp.match(/^[0-9]+$/g)
			Math.pow(10, mdp.length)

		# Mot de passe alphabétique mono-casse*
		when mdp.match(/^[a-z]+$/g) or mdp.match(/^[A-Z]+$/g)
			Math.pow(26, mdp.length)

		# Casses courantes :
		when mdp.match(/^[A-Z][a-z]+$/g) or mdp.match(/^[a-z]+[A-Z]$/g) or mdp.match(/^[a-z][A-Z]+$/g) or mdp.match(/^[A-Z]+[a-z]$/g)
			4 * Math.pow(26, mdp.length)

		# Mot de passe dont seule le premier caractère n'est pas une lettre et ou le reste est mono-casse*
		when mdp.match(/^.[a-z]+$/g) or mdp.match(/^.[A-Z]+$/g) or mdp.match(/^[a-z]+.$/g) or mdp.match(/^[A-Z]+.$/g)
			50 * Math.pow(26, mdp.length - 1)

		# Mot de passe alpha-numérique mono-casse*
		when mdp.match(/^[0-9a-z]+$/g) or mdp.match(/^[0-9A-Z]+$/g)
			Math.pow(36, mdp.length)

		# Mot de passe sans lettre
		when mdp.match(/^[^A-Za-z]+$/g)
			Math.pow(42, mdp.length)

		# Mot de passe sans nombre ni minuscule ou sans nombre ni majuscule
		when mdp.match(/^[^0-9a-z]+$/g) or mdp.match(/^[^0-9A-Z]+$/g)
			Math.pow(50, mdp.length)

		# Mot de passe alphabétique
		when mdp.match(/^[a-zA-Z\s]+$/g)
			Math.pow(52, mdp.length)

		# Mot de passe sans nombre ou sans minuscule ou sans majuscule
		when mdp.match(/^[^0-9]+$/g) or mdp.match(/^[^A-Z]+$/g) or mdp.match(/^[^a-z]+$/g)
			Math.pow(68, mdp.length)

		# Mot de passe complexe
		else
			Math.pow 100, mdp.length


# Refresh pill counter
refreshPill = ->
	$('.notifications').each ->
		$ul = $ @
		count = $ul.find('ul li').length
		if count
			$ul.find('.pill').show().text count
		else
			$ul.find('.pill').hide()

# Execute a callback when recorded then each time the window is resized
onResize = (fct) ->
	$(window).resize fct
	fct.call @
