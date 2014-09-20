# Piwik
if (piwikSettings = getData 'piwik')
	_paq = _paq or []
	_paq.push ["trackPageView"]
	_paq.push ["enableLinkTracking"]
	(->
		u = ((if ("https:" is document.location.protocol) then "https" else "http")) + "://" + (piwikSettings.host || 'piwik') + "/"
		_paq.push [
			"setTrackerUrl"
			u + "piwik.php"
		]
		_paq.push [
			"setSiteId"
			(piwikSettings.id || 1)
		]
		d = document
		g = d.createElement("script")
		s = d.getElementsByTagName("script")[0]
		g.type = "text/javascript"
		g.defer = true
		g.async = true
		g.src = u + "piwik.js"
		s.parentNode.insertBefore g, s
		return
	)()

# Google Analytics
if (googleAnalyticsSettings = getData 'googleAnalytics')
	((w, d, s, u, g, a, m) ->
		w["GoogleAnalyticsObject"] = g
		w[g] = w[g] or ->
			(w[g].q = w[g].q or []).push arguments
			return
		w[g].l = 1 * new Date()
		a = d.createElement(s)
		m = d.getElementsByTagName(s)[0]
		a.async = 1
		a.src = u
		m.parentNode.insertBefore a, m
		return
	) window, document, "script", "//www.google-analytics.com/analytics.js", (googleAnalyticsSettings.callback || "ga")
	ga "create", (googleAnalyticsSettings.id || ""), "auto"
	ga "send", "pageview"