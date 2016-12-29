
do ->

    w = null
    $tester = null
    shouldExists = _shouldExists
    shouldNotExists = _shouldNotExists

    testWith '/', (a, b, c, d) ->
        $tester = a
        w = b
        shouldExists = c
        shouldNotExists = d

    describe "Mobile", ->

        it "should adapt header with device width", (done) ->

            $tester.width 700
            shouldExists '.wornet-navbar.mobile-device:visible', ".wornet-navbar.mobile-device:visible must exist in 700px-width"
            shouldNotExists '.wornet-navbar.mobile-device:hidden', ".wornet-navbar.mobile-device:visible must not exist in 700px-width"
            shouldNotExists '.wornet-navbar.standard-device:visible', ".wornet-navbar.standard-device:visible must not exist in 700px-width"
            shouldExists '.wornet-navbar.standard-device:hidden', ".wornet-navbar.mobile-device:visible must exist in 700px-width"
            shouldNotExists '.open-shutter:visible', '[role="menu"]:visible must not exist in 700px-width'
            shouldExists '.open-shutter:hidden', '[role="menu"]:hidden must exist in 700px-width'
            $tester.width 800
            shouldNotExists '.wornet-navbar.mobile-device:visible', ".navbar-toggle.collapsed:visible must not exist in 800px-width"
            shouldExists '.wornet-navbar.mobile-device:hidden', ".navbar-toggle.collapsed:visible must exist in 800px-width"
            shouldExists '.wornet-navbar.standard-device:visible', ".navbar-toggle.collapsed:visible must exist in 800px-width"
            shouldNotExists '.wornet-navbar.standard-device:hidden', ".navbar-toggle.collapsed:visible must not exist in 800px-width"
            shouldExists '.open-shutter:visible', '[role="menu"]:visible must exist in 800px-width'
            shouldNotExists '.open-shutter:hidden', '[role="menu"]:hidden must not exist in 800px-width'
            done()

    describe "Status loading", ->

        it "need a Status controller", ->

            shouldExists '[ng-controller="StatusCtrl"]', 'StatusCtrl must exist'

    describe "Status post", ->

        it "simple status", ->

            shouldExists '.status-form form', '.status-form form should exist'
            shouldExists '.status-form form .publish', '.status-form form .publish should exist'
            shouldExists '.status-form form .publish input', '.status-form form .publish input should exist'
            $form = w.$ '.status-form form'
            $form.find('textarea').set('Bonjour, ceci est un test unitaire').focus().click()
            $form.find('.publish input').click()
            delay 5000, ->
                $status = w.$ '.status-block:first'
                expect($status.find('.status-content:last').html()).toBe "Bonjour, ceci est un test unitaire"
