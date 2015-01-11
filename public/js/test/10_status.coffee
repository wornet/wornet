
describe "Mobile", ->

	w = null
	$tester = null

	beforeEach (done) ->
		iframeLoad '/', ->
			$tester = $ @
			w = @contentWindow
			w.$ ->
				do done
				return

	it "should adapt header with device width", ->

		$tester.width 700
		expect(w.exists '.navbar-toggle.collapsed:visible').toBe true, ".navbar-toggle.collapsed:visible must exist in 700px-width"
		expect(w.exists '.navbar-toggle.collapsed:hidden').toBe false, ".navbar-toggle.collapsed:hidden must not exist in 700px-width"
		expect(w.exists '.open-shutter:visible').toBe false, '[role="menu"]:visible must not exist in 700px-width'
		expect(w.exists '.open-shutter:hidden').toBe true, '[role="menu"]:hidden must exist in 700px-width'
		$tester.width 800
		expect(w.exists '.navbar-toggle.collapsed:visible').toBe false, ".navbar-toggle.collapsed:visible must not exist in 800px-width"
		expect(w.exists '.navbar-toggle.collapsed:hidden').toBe true, ".navbar-toggle.collapsed:hidden must exist in 800px-width"
		expect(w.exists '.open-shutter:visible').toBe true, '[role="menu"]:visible must exist in 800px-width'
		expect(w.exists '.open-shutter:hidden').toBe false, '[role="menu"]:hidden must not exist in 800px-width'

###

	describe "Status", ->

		describe "Status loading", ->

			it "need a Status controller", ->

				expect(w.exists '[ng-controller="StatusCtrl"]').toBe true, 'StatusCtrl must exist'

###
