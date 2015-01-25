
describe "Mobile", ->

	w = null
	$tester = null
	shouldExists = _shouldExists
	shouldNotExists = _shouldNotExists

	testWith '/', (a, b, c, d) ->
		$tester = a
		w = b
		shouldExists = c
		shouldNotExists = d

	it "should adapt header with device width", (done) ->

		$tester.width 700
		shouldExists '.navbar-toggle.collapsed:visible', ".navbar-toggle.collapsed:visible must exist in 700px-width"
		shouldNotExists '.navbar-toggle.collapsed:hidden', ".navbar-toggle.collapsed:hidden must not exist in 700px-width"
		shouldNotExists '.open-shutter:visible', '[role="menu"]:visible must not exist in 700px-width'
		shouldExists '.open-shutter:hidden', '[role="menu"]:hidden must exist in 700px-width'
		$tester.width 800
		shouldNotExists '.navbar-toggle.collapsed:visible', ".navbar-toggle.collapsed:visible must not exist in 800px-width"
		shouldExists '.navbar-toggle.collapsed:hidden', ".navbar-toggle.collapsed:hidden must exist in 800px-width"
		shouldExists '.open-shutter:visible', '[role="menu"]:visible must exist in 800px-width'
		shouldNotExists '.open-shutter:hidden', '[role="menu"]:hidden must not exist in 800px-width'
		done()

###

	describe "Status", ->

		describe "Status loading", ->

			it "need a Status controller", ->

				expect(w.exists '[ng-controller="StatusCtrl"]', 'StatusCtrl must exist'

###
