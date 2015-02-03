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
				if failureCount isnt 0
					alert 'There are failures in client-side unit tests'
				else if totalSpecsDefined isnt specsExecuted
					alert 'All the specs defined have not been executed'
				else
					window.close()
			else
				console.warn 'Standalone test page'
