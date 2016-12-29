module.exports = (lang, text, replacements, count) ->

    if ! empty(count) || count is 0
        floatCount = parseFloat(count)
        floatReplacements = parseFloat(replacements)
        if isNaN(floatCount) && ! isNaN(floatReplacements)
            replacement = count
            count = floatReplacements
        else if ! isNaN(floatCount)
            count = floatCount
        else
            throw "count is not a valid number"
        replacements.count = count

    else if typeof(replacements) is 'object' && (! empty(replacements.count) || replacements.count is 0)
        floatCount = parseFloat(replacements.count)
        if ! isNaN(floatReplacements)
            count = floatCount

    replacements ||= {}

    for from, to of replacements
        reg = new RegExp '\\{' + from + '\\}', 'g'
        text = text.replace reg, to

    texts = text.split /\|/g
    if count? && texts.length isnt 1
        zero = false
        if texts.length is 3
            if count is 0
                text = texts[0]
                zero = true
            else
                texts = texts.slice(1)
        if texts.length > 2
            unless zero
                throw "No more than 2 pipes are supported in a plurializable text"
        switch lang

            # In english
            when "en"
                singular = count is 1

            # In french
            else
                singular = count > -2 && count < 2

        text = texts[if singular then 0 else 1]

    text
