'use strict'

textReplacements = (text, replacements, count = null) ->
	unless count is null
		texts = text.split /\|/g
		if texts.length > 1
			if texts.length is 2
				texts.unshift texts[0]
			count = Math.abs Math.floor count
			count = Math.min count, texts.length - 1
			text = texts[count]
	for key, value of replacements
		text = text.replace(new RegExp('\\{' + key + '\\}', 'g'), value)
	text

do (d = Date) ->
	prototype = d.prototype
	s = textReplacements
	toString = prototype.toString
	prototype.isValid = ->
		@toString() isnt 'Invalid Date'
	prototype.midnight = ->
		@setHours 0
		@setMinutes 0
		@setSeconds 0
		@setMilliseconds 0
		@
	prototype.toString = (str) ->
		if str
			str = str.replace(/YYYY/g, @getFullYear())
			month = @getMonth() + 1
			mm = (if month < 10 then '0' else '') + month
			day = @getDate()
			dd = (if day < 10 then '0' else '') + day
			hour = @getHours()
			hh = (if hour < 10 then '0' else '') + hour
			minute = @getMinutes()
			ii = (if minute < 10 then '0' else '') + minute
			second = @getSeconds()
			ss = (if minute < 10 then '0' else '') + second
			str = str.replace /MM/g, mm
			str = str.replace /M/g, month
			str = str.replace /DD/g, dd
			str = str.replace /D/g, day
			str = str.replace /HH/g, hh
			str = str.replace /H/g, hour
			str = str.replace /ii/g, ii
			str = str.replace /i/g, minute
			str = str.replace /SS/g, ss
			str = str.replace /S/g, second
			str
		else
			toString.call @
	prototype.addSeconds = (i) ->
		@setSeconds @getSeconds() + i
		@
	prototype.subSeconds = (i) ->
		@setSeconds @getSeconds() - i
		@
	prototype.addMinutes = (i) ->
		@setMinutes @getMinutes() + i
		@
	prototype.subMinutes = (i) ->
		@setMinutes @getMinutes() - i
		@
	prototype.addHours = (i) ->
		@setHours @getHours() + i
		@
	prototype.subHours = (i) ->
		@setHours @getHours() - i
		@
	prototype.addDays = (i) ->
		@setDate @getDate() + i
		@
	prototype.subDays = (i) ->
		@setDate @getDate() - i
		@
	prototype.yesterday = ->
		@subDays 1
		@
	prototype.tomorrow = ->
		@addDays 1
		@
	prototype.addMonths = (i) ->
		@setMonth @getMonth() + i
		@
	prototype.subMonths = (i) ->
		@setMonth @getMonth() - i
		@
	prototype.addYears = (i) ->
		@setFullYear @getFullYear() + i
		@
	prototype.subYears = (i) ->
		@setFullYear @getFullYear() - i
		@
	prototype.humanDate = (plain) ->
		if plain or @ < (new d).yesterday().midnight()
			@toString s("DD/MM/YYYY")
		else if @ < (new d).midnight()
			s("Hier")
		else
			s("Ajourd'hui")
	prototype.humanTime = (plain) ->
		if plain or @ < (new d).subMinutes 50
			@toString s("HH:ii")
		else if @ < (new d).subSeconds 40
			s("Il y a {minutes} minutes", { minutes: Math.max(1, (new d).getMinutes() - @getMinutes()) })
		else
			s("Maintenant")
	prototype.humanDateTime = (plain) ->
		if plain or @ < (new d).yesterday().midnight()
			@toString s("DD/MM/YYYY à HH:ii")
		else if @ < (new d).midnight()
			s("Hier à {time}", { time: @toString(s("HH:ii")) })
		else if @ < (new d).subMinutes 50
			s("Aujourd'hui à {time}", { time: @toString(s("HH:ii")) })
		else if @ < (new d).subSeconds 40
			s("Il y a {minutes} minutes", { minutes: Math.max(1, Math.ceil(((new d).getTime() - @getTime()) / 60000)) })
		else
			s("Maintenant")
	prototype.age = (now) ->
		unless now instanceof Date and now.isValid()
			now = new d
		date = new d(@)
		age = now.getFullYear() - date.getFullYear()
		m = now.getMonth() - date.getMonth()
		if m < 0 or (m is 0 and now.getDate() < date.getDate())
			age--
		age
	d.fromId = (id) ->
		new d(parseInt(id.toString().slice(0,8), 16)*1000)
