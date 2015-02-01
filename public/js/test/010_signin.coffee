
describe "Signin", ->

	w = null
	$tester = null
	shouldExists = _shouldExists
	shouldNotExists = _shouldNotExists
	click = null

	testWith '/user/logout', (a, b, c, d) ->
		$tester = a
		w = b
		shouldExists = c
		shouldNotExists = d
		click = (selector) ->
			w.$(selector)[0].click()

	describe "Logout", ->

		it "should redirect to the home page", (done) ->

			signinUrl = '/user/signin'

			sequence (fulfill, reject) ->
				expect(url w).toBe '/'
				shouldExists '.tooltip:hidden'
				shouldNotExists '.tooltip:visible'
				$form = w.$ '#signin'
				$form.find('input[name="email"]').set('invalid').focus().click()
				shouldExists '.tooltip:visible'
				$tester.form $form, fulfill, reject

			.then (fulfill, reject) ->
				expect(w.$('[ng-controller="SigninSecondStepCtrl"] input[name="email"]').val()).toBe 'invalid'
				shouldExists 'input[name="birthDate"]:visible'
				$tester.src signinUrl, fulfill, reject

			.then (fulfill, reject) ->
				shouldExists 'input[name="birthDate"]:visible'
				$tester.form fulfill, reject

			.then (fulfill, reject) ->
				expect(url w).toBe signinUrl
				$tester.complete
					email: 'unit-test@selfbuild.fr'
					password: 'azer8TyG'
					passwordCheck: 'azer8Ty'
					'name.first': 'Bob'
					'name.last': 'Dylan'
					birthDate: '1990-01-07'
					legals: true
				.form fulfill, reject

			.then (fulfill, reject) ->
				expect(url w).toBe signinUrl
				$tester.complete
					email: 'unit-test@selfbuild.fr'
					password: 'azer8Ty'
					passwordCheck: 'azer8Ty'
					'name.first': 'Bob'
					'name.last': 'Dylan'
					birthDate: '1850-01-07'
					legals: true
				.form fulfill, reject

			.then (fulfill, reject) ->
				expect(url w).toBe signinUrl
				$tester.complete
					email: 'unit-test@selfbuild.fr'
					password: 'azer8Ty'
					passwordCheck: 'azer8Ty'
					'name.first': 'Bob'
					'name.last': 'Dylan'
					birthDate: '1990-01-07'
					legals: false
				.form fulfill, reject

			.then (fulfill, reject) ->
				expect(url w).toBe signinUrl
				$tester.complete
					email: 'unit-test@selfbuild.fr'
					password: 'azer8Ty'
					passwordCheck: 'azer8Ty'
					'name.first': 'Bob'
					'name.last': 'Dylan'
					birthDate: '1990-01-07'
					legals: true
				.form fulfill, reject

			.then (fulfill, reject) ->
				expect(url w).toBe '/user/welcome'
				shouldNotExists '.alert-danger'
				shouldExists 'a[href~="/user/profile"]'
				$tester.link 'a[href~="/user/profile"]', fulfill, reject

			.then (fulfill, reject) ->
				shouldExists '.dropdown-toggle:icontains("Bob Dylan")'
				shouldExists 'h3:icontains("Bob Dylan")'
				shouldExists '#shutter:hidden'
				click '.open-shutter'
				delay 200, ->
					shouldExists '#shutter:visible'
					shouldExists 'a[href~="/user/settings"]:visible'
					$tester.link 'a[href~="/user/settings"]', fulfill, reject

			.then (fulfill, reject) ->
				shouldExists '#delete-account:visible'
				shouldNotExists '#delete-account-password'
				click '#delete-account:visible'
				delay 200, ->
					shouldExists '#delete-account-password:visible'
					w.$('#delete-account-password').val('azer8Ty')
						.parents('.modal-content:first')
						.find('.btn-primary:last')[0]
						.click()
					$tester.page fulfill, reject

			.then ->
				expect(url w).toBe '/'
				shouldExists '#login'
				shouldExists '#signin'
				done()

			.catch (error) ->
				if error instanceof Error
					delay 1, ->
						throw error
				expect('Page loading').toBe 'ok'
				done()
