do (window, navigator, s = textReplacements) ->
    # No click delay with phone touch
    if window.FastClick
        FastClick.attach document.body

    # Default errors
    window.SERVER_ERROR_DEFAULT_MESSAGE = s("Perte de la connexion internet. La dernière action n'a pas pu être effectuée.")

    preventOutGoing = exists 'iframe.app'

    # Display a loading animation when page is loading
    window.onbeforeunload = (event) ->
        window._e = event
        $(window).scrollTop(0);
        # $.xhrPool.isWaiting() or
        somethingWaiting = do ->
            allEmpty = true
            $selection = $ '.do-not-loose'
            if window.$lastForm
                $selection = $selection.not window.$lastForm.find '.do-not-loose'
            $selection.each ->
                if $(@).val()
                    allEmpty = false
                    false
                else
                    true
            ! allEmpty
        if preventOutGoing
            preventOutGoing = false
            return s("Attention, l'application tente de vous faire quitter Wornet, pour profiter de l'application sans quitter Wornet, cliquez sur [Rester sur la page]")
        else if somethingWaiting
            return s("Attention, des modifications n'ont pas encore été sauvegardées.")
        else
            $.xhrPool.abortAll()
            showLoader()
        return

    if preventOutGoing
        $('iframe.app').load ->
            delay 500, ->
                preventOutGoing = false
                return
            return

    $(window)
        .on "offline", ->
            $('.errors').warnings s("Attention, vous n'êtes plus connecté à Internet")
            return

        .on "online", ->
            $('.errors').infos s("Connexion Internet rétablie")
            return

    window.bootboxTexts ||= en: {}
    texts = bootboxTexts
    texts.en =
        OK: s("OK")
        CANCEL: s("Non")
        CONFIRM: s("Oui")
    window.confirmButtons = (callback) ->
        no:
            label: texts.en.CANCEL
        yes:
            label: texts.en.OK
            callback: callback

    userAgent = (navigator || {}).userAgent || ''

    if ~userAgent.indexOf 'Android'
        $('body').addClass 'android'

    if (~userAgent.indexOf 'iPhone') || (~userAgent.indexOf 'iPad')
        $document
        .on 'mouseover', '.m-btns a, .m-btns .btn', (e) ->
            $(@).click()
            cancel e
        .on 'touchstart', '.open-shutter a', ->
            $a = $ 'ul.nav > li > a'
            href = $a.attr 'href'
            $a.removeAttr 'href'
            $a.click ->
                delay ->
                    $a.attr 'href', href
                    return
                return
            return

    # Fix iOS missing placeholder on date inputs
    $('input[type="date"]').each ->
        $date = $ @
        width = $date.width()
        if width > 0 and width < 130
            $date.attr 'type', 'text'
                .on 'focus touchstart', ->
                    if 'text' is $date.attr 'type'
                        $date.blur()
                        delay 1, ->
                            $date.attr 'type', 'date'
                                .focus()

    return

# Convert titles attributes to tooltips when elements have a data-toggle="tooltip" atribute
$('[data-toggle="tooltip"]:not([data-original-title])').tooltip()

countLoaders = ->
    unless exists '.loading'
        $document.trigger 'end-of-load'
        if exists '.notifications'
            waitForNotify()

# Display loading animation until angular scope is ready
$('.loading').each ->
    $loading = $ @
    $loading.ready ->
        $scope = $loading.scope()
        $loading.removeClass 'loading'
        if $scope
            refreshScope $scope
            countLoaders()
        return
    return

unless exists '#shutter'
    $('.opened-shutter').removeClass 'opened-shutter'

# Force the height of the elements (with data-ratio attribute) to keep the specified ratio
# And refresh each time the window is resized
onResize ->
    $('iframe.app').height $('body').height() - 72
    $('[data-ratio]').ratio()
    return
