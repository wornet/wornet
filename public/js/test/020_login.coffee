
describe "Login", ->

	w = null
	$tester = null
	shouldExists = _shouldExists
	shouldNotExists = _shouldNotExists
	click = null

	testWith '/', (a, b, c, d) ->
		$tester = a
		w = b
		shouldExists = c
		shouldNotExists = d
		click = (selector) ->
			w.$(selector)[0].click()

	describe "Wrong login", ->

		it "should fail", (done) ->

			expect(url w).toBe '/'
			shouldExists '#login'
			$form = w.$ '#login'
			fail = ->
				shouldExists '.alert-danger'
				shouldExists '#login'
				shouldNotExists '#search'
				done()
			$tester.complete '#login',
				email: 'unit-test@selfbuild.fr'
				password: 'azer8Ty'
			.form '#login', ->
				expect('Page loading').toBe 'ko'
				done()
			, fail
			w.$document.ajaxComplete fail

	describe "Good login", ->

		it "should succeed", (done) ->

			expect(url w).toBe '/'
			shouldExists '#login'
			success = ->
				shouldNotExists '.alert-danger'
				shouldNotExists '#login'
				shouldExists '#search'
				done()
			$tester.complete '#login',
				email: 'unit-test-login@selfbuild.fr'
				password: 'azer8Ty'
			.form '#login', success, ->
				expect('Page loading').toBe 'ok'
				done()
			w.$document.ajaxComplete (event, xhr) ->
				goTo = 'undefined'
				try
					data = $.parseJSON xhr.responseText
					goTo = data.goingTo
				catch e
				expect(goTo).toBe '/'
				unless goTo is '/'
					success
