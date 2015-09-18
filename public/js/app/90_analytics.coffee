# Piwik
if (piwikSettings = getData 'piwik')
	window['_' + 'paq'] = (paq = window['_' + 'paq'] || [])
	do ->
		i = 0
		for key, val of getData 'vars'
			paq.push ['setCustomVariable', ++i, key, val, "visit"]
	paq.push ['trackPageView']
	paq.push ['enableLinkTracking']
	paq.push ['setTrackerUrl', (piwikSettings.host || '') + '/stat']
	paq.push ['setUserId', getCachedData 'me']
	paq.push ['setSiteId', piwikSettings.id]

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
