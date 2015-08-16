# Piwik
if (piwikSettings = getData 'piwik')
	_paq = _paq || []
	do ->
		i = 0
		for key, val of getData 'vars'
			_paq.push ['setCustomVariable', ++i, key, val, "visit"]
	_paq.push ['trackPageView']
	_paq.push ['enableLinkTracking']
	_paq.push ['setTrackerUrl', (piwikSettings.host || '') + '/stat']
	_paq.push ['setUserId', getCachedData 'me']
	_paq.push ['setSiteId', piwikSettings.id]

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
