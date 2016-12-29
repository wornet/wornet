# Cookies information banner
if exists '.cookiesWarning'
    bodyBottomPadding = parseInt $('body').css('padding-bottom')
    $warnings = $('.cookiesWarning')
    $warnings.find('.ok').click ->
        $warnings.slideUp ->
            $warnings.remove()
    onResize ->
        $('body').css 'padding-bottom', $('#cookiesWarning').outerHeight() + (if isNaN(bodyBottomPadding) then 0 else bodyBottomPadding)

# Agenda
if exists '.calendar'
    dateTexts = getData('dateTexts')
    calendarGetText = (name) ->
        if typeof(dateTexts[name]) is 'undefined'
            console.warn name + " calendar text not found."
            console.trace()
        dateTexts[name]
