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
	((w, g) ->
		w["GoogleAnalyticsObject"] = g
		w[g] = w[g] or ->
			(w[g].q = w[g].q or []).push arguments
			return
		return
	) window, (googleAnalyticsSettings.callback || "ga")
