unless window["note_jaime_fonctions_chargees"]
	note_jaime_gid = (id) ->
		return document.getElementById(id)	if document.getElementById(id)
		false
	note_jaime_isclass = (elt, nom) ->
		return false	unless elt.className
		reg = new RegExp("\\s" + nom + "\\s", "gi")
		(" " + elt.className + " ").match reg
	note_jaime_over = (id, num) ->
		note_jaime_gid("note_jaime_" + id).style.backgroundImage = "url('" + note_jaime_infos[id].jaimeh + "')"
		return
	note_jaime_out = (id) ->
		note_jaime_gid("note_jaime_" + id).style.backgroundImage = "url('" + note_jaime_infos[id].jaime + "')"
		return
	note_jaime_dsl = (src) ->
		s = document.createElement("script")
		s.setAttribute "type", "text/javascript"
		s.setAttribute "src", src
		document.body.appendChild s
		return
	note_jaime_js = (id, i) ->
		" id=\"note_jaime_" + id + "\" onmouseover=\"note_jaime_over('" + id + "'," + i + ");\" onmouseout=\"note_jaime_out('" + id + "');\" onclick=\"note_jaime_clic('" + id + "'," + i + ");\""
	note_jaime_clic = (id, i) ->
		note_jaime_dsl "http://starpush.selfbuild.fr/dsl.js.php?jaime&note=" + ((if i is 2 then 2 else 1)) + "&ref=" + id
		return
	note_jaime_retour = (id, note, total, notes, min, max, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10) ->
		note_jaime_memo.id = id
		out = undefined
		if note > 0
			out = "\t<a style=\"" + note_jaime_style("star jaimeg") + "\">&nbsp;</a> <span style=\"" + note_jaime_style("cote") + "\">" + n1 + "</span>"
		else if total > 0
			out = "\t<a" + note_jaime_js(id, 1) + " style=\"" + note_jaime_style("star") + " cursor:pointer;\">&nbsp;</a> <span style=\"" + note_jaime_style("cote") + "\">" + n1 + "</span>"
		else
			out = "\t<a" + note_jaime_js(id, 1) + " style=\"" + note_jaime_style("star") + " cursor:pointer;\">&nbsp;</a> <span style=\"" + note_jaime_style("cote") + "\">0</span>"
		note_jaime_gid("boite_" + id).innerHTML = out + "<span style=\"clear:both; display:block;\"></span>"
		return
	note_jaime_boite_over = (boite) ->
		if boite.hasChildNodes()
			elts = boite.childNodes
			i = 0

			while i < elts.length
				elts[i].style.display = "block"	if note_jaime_isclass(elts[i], "cache")
				i++
			boite.style.zIndex = 2
			boite.style.position = "relative"
		return
	note_jaime_boite_out = (boite) ->
		if boite.hasChildNodes()
			$.each boite.childNodes, ->
				@style.display = "none"	if note_jaime_isclass(@, "cache")
			boite.style.position = ""
			boite.style.zIndex = 1
		return
	note_jaime_style = (st) ->
		id = note_jaime_memo.id
		style = "display:block;"
		st = st.split(/\s+/g)
		for i of st
			if window["note_jaime_styles"][st[i]]
				style += " " + window["note_jaime_styles"][st[i]]
				if note_jaime_infos[id]
					if st[i] is "star"
						style += " background-image:url('" + note_jaime_infos[id].jaime + "'); width:" + note_jaime_infos[id].n_width + "px; height:" + note_jaime_infos[id].n_height + "px;"
					else style += " background-image:url('" + note_jaime_infos[id].jaimeg + "');"	if st[i] is "gris"
					style += " margin:2px;"	if note_jaime_infos[id].margin
		style
	note_jaime_verifie = ->
		ids = []
		bonusHeight = 6
		$('[data-starpush]').each ->
			$starpush = $ @
			id = $starpush.data 'starpush'
			$starpush.removeData 'starpush'
			pos = "note_jaime_right"
			type = "right"
			nostyle = $starpush.is '.nostyle'
			note_jaime_infos[id] = {}
			note_jaime_infos[id].nohalf = false
			note_jaime_infos[id].margin = false
			note_jaime_infos[id].n_width = 26
			note_jaime_infos[id].n_height = 12 + bonusHeight
			infos = [
				'/img/w-gray.png'
				'/img/w-orange.png'
				'/img/w-black.png'
			]
			img1 = new Image()
			img1.onload = ((id, img) ->
				->
					note_jaime_infos[id].jaime = img.src
					note_jaime_infos[id].jaimeh = decodeURIComponent(infos[1])
					note_jaime_infos[id].jaimeg = decodeURIComponent(infos[2])
					(new Image()).src = note_jaime_infos[id].jaimeg
					(new Image()).src = note_jaime_infos[id].jaimeh
					window["note_jaime_styles"].jaime = "background-image:url('" + note_jaime_infos[id].jaime + "');"
					window["note_jaime_styles"].jaimeh = "background-image:url('" + note_jaime_infos[id].jaimeh + "');"
					window["note_jaime_styles"].jaimeg = "background-image:url('" + note_jaime_infos[id].jaimeg + "');"
					note_jaime_infos[id].n_width = img.width
					note_jaime_infos[id].n_height = img.height + bonusHeight
					note_jaime_dsl "http://starpush.selfbuild.fr/get.js.php?jaime&ref=" + id	if note_jaime_memo.demarrage
					return
			)(id, img1)
			img1.onerror = ->
				note_jaime_infos[id].jaime = "http://starpush.selfbuild.fr/images/jaime.png"
				note_jaime_infos[id].jaimeh = "http://starpush.selfbuild.fr/images/jaimeh.png"
				note_jaime_infos[id].jaimeg = "http://starpush.selfbuild.fr/images/jaimeg.png"
				(new Image()).src = note_jaime_infos[id].jaimeg
				(new Image()).src = note_jaime_infos[id].jaimeh
				window["note_jaime_styles"].jaime = "background-image:url('" + note_jaime_infos[id].jaime + "');"
				window["note_jaime_styles"].jaimeh = "background-image:url('" + note_jaime_infos[id].jaimeh + "');"
				window["note_jaime_styles"].jaimeg = "background-image:url('" + note_jaime_infos[id].jaimeg + "');"
				return

			img1.src = decodeURIComponent(infos[0])
			div = document.createElement("div")
			div.setAttribute "style", note_jaime_style(pos)
			@appendChild div
			out = ""
			out += "<div"
			if type is "right"
				out += " style=\"" + note_jaime_style("nr1") + " text-align:right;\""
			else if type is "left"
				out += " style=\"" + note_jaime_style("nl1") + " text-align:right;\""
			else
				out += " style=\"width:300px; text-align:right;\""
			out += "><div style=\""
			out += "float:" + type + ";"	if type isnt "none"
			out += note_jaime_style("n2")	unless nostyle
			out += "\" class=\"note_jaime_div\" id=\"boite_" + id + "\" onmouseout=\"note_jaime_boite_out(this);\" onmouseover=\"note_jaime_boite_over(this);\">&nbsp;</div></div>"
			div.innerHTML = out
			ids.push id
		note_jaime_memo.demarrage = true
		$.each ids, ->
			note_jaime_dsl "http://starpush.selfbuild.fr/get.js.php?jaime&ref=" + @
		return
	note_jaime_fonctions_chargees = true
	window["note_jaime_styles"] =
		note_jaime_left: "float:left; position:relative; height:22px;"
		note_jaime_right: "float:right; position:relative; height:22px;"
		right: "float:right;"
		cote: "float:right; display:block; padding:0 9px 0 2px;"
		star: "display:block; background-position:left center; background-repeat:no-repeat; width:24px; height:24px; text-decoration:none; float:right; font-size:1px;"
		nr1: "position:absolute; top:0; right:0; width:300px;"
		nl1: "position:absolute; top:0; left:0; width:300px;"
		n2: "box-shadow:1px 1px 1px #efefef; border:1px solid #dddddd; border-radius:4px; -o-border-radius:4px; -moz-border-radius:4px; -imac-border-radius:4px; -khtml-border-radius:4px; -webkit-border-radius:4px; border-radius:4px; padding:3px; background:white; white-space:nowrap;"
		stop: "clear:both; display:block;"
		cache: "display:none;"

	window["note_jaime_memo"] = {}
	note_jaime_memo.demarrage = false
	window["note_jaime_infos"] = {}

starPush = note_jaime_verifie