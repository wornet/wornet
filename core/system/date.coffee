'use strict'

do (d = Date) ->
	toString = d.prototype.toISOString
	d.prototype.log = ->
		@setHours(@getHours() + 2)
		@toISOString().replace(/Z$/g, '').replace('T', '  ')
	d.prototype.isValid = ->
		@toString() isnt 'Invalid Date'
	d.prototype.midnight = ->
		@setHours 0
		@setMinutes 0
		@setSeconds 0
		@
	d.prototype.toString = (str) ->
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
	d.prototype.addSeconds = (i) ->
		@setSeconds @getSeconds() + i
		@
	d.prototype.subSeconds = (i) ->
		@setSeconds @getSeconds() - i
		@
	d.prototype.addMinutes = (i) ->
		@setMinutes @getMinutes() + i
		@
	d.prototype.subMinutes = (i) ->
		@setMinutes @getMinutes() - i
		@
	d.prototype.addHours = (i) ->
		@setHours @getHours() + i
		@
	d.prototype.subHours = (i) ->
		@setHours @getHours() - i
		@
	d.prototype.addDays = (i) ->
		@setDate @getDate() + i
		@
	d.prototype.subDays = (i) ->
		@setDate @getDate() - i
		@
	d.prototype.yesterday = ->
		@subDays 1
		@
	d.prototype.tomorrow = ->
		@addDays 1
		@
	d.prototype.addMonths = (i) ->
		@setMonth @getMonth() + i
		@
	d.prototype.subMonths = (i) ->
		@setMonth @getMonth() - i
		@
	d.prototype.addYears = (i) ->
		@setFullYear @getFullYear() + i
		@
	d.prototype.subYears = (i) ->
		@setFullYear @getFullYear() - i
		@
	d.prototype.humanDate = (plain) ->
		if plain or @ < (new d).yesterday().midnight()
			@toString s("DD/MM/YYYY")
		else if @ < (new d).midnight()
			s("Hier")
		else
			s("Ajourd'hui")
	d.prototype.humanTime = (plain) ->
		if plain or @ < (new d).subMinutes 50
			@toString s("HH:ii")
		else if @ < (new d).subSeconds 40
			s("Il y a {minutes} minutes", { minutes: Math.max(1, Math.ceil(((new d).getTime() - @getTime()) / 60000)) })
		else
			s("Il y a {seconds} secondes", { seconds: Math.max(1, Math.ceil(((new d).getTime() - @getTime()) / 1000)) })
	d.prototype.humanDateTime = (plain) ->
		if plain or @ < d.yesterday().midnight()
			@toString s("DD/MM/YYYY à HH:ii")
		else if @ < (new d).midnight()
			s("Hier à {time}", { time: @toString(s("HH:ii")) })
		else if @ < (new d).subMinutes 50
			s("Aujourd'hui à {time}", { time: @toString(s("HH:ii")) })
		else if @ < (new d).subSeconds 40
			s("Il y a {minutes} minutes", { minutes: Math.max(1, Math.ceil(((new d).getTime() - @getTime()) / 60000)) })
		else
			s("Il y a {seconds} secondes", { seconds: Math.max(1, Math.ceil(((new d).getTime() - @getTime()) / 1000)) })
	d.prototype.age = (now) ->
		unless now instanceof Date and now.isValid()
			now = new d
		date = new d(@)
		age = now.getFullYear() - date.getFullYear()
		m = now.getMonth() - date.getMonth()
		if m < 0 or (m is 0 and now.getDate() < date.getDate())
			age--
		age
	d.log = ->
		console['log'] (new d).log()
	d.fromId = (id) ->
		new d(parseInt(id.toString().slice(0,8), 16)*1000)
	d.yesterday = ->
		(new d).yesterday()
	d.year = ->
		(new d).getFullYear()
