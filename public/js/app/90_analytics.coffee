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
