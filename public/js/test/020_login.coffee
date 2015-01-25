
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
			$tester.complete
				email: 'unit-test@selfbuild.fr'
				password: 'azer8Ty'
			.form ->
				shouldExists '#login'
				shouldNotExists '#search'
				done()

	describe "Good login", ->

		it "should succeed", (done) ->

			expect(url w).toBe '/'
			shouldExists '#login'
			$form = w.$ '#login'
			$form.complete
				email: 'unit-test-login@selfbuild.fr'
				password: 'azer8Ty'
			.form ->
				shouldNotExists '#login'
				shouldExists '#search'
				done()
