jasmineComplete = (totalSpecsDefined, specsExecuted, failureCount) ->
	$.ajax '/test/results',
		type: 'POST'
		dataType: 'json'
		data:
			_csrf: $('meta[name="_csrf"]').prop 'content'
			totalSpecsDefined: totalSpecsDefined
			specsExecuted: specsExecuted
			failureCount: failureCount
			successCount: specsExecuted - failureCount
		success: (data) ->
			if data.functionExists
				console['log'] 'Receive results'
				$('iframe').remove()
				window.close()
			else
				console.warn 'Standalone test page'
