splitPattern = (str, escape = false) ->
    if escape
        str = str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"
    '(' + str.accents(true).replace(/\s+/g, '|') + ')'

StringUtils =
    accents: (toRegEpx = false) ->
        letters =
            a: 'âàäã'
            e: 'éèêë'
            c: 'ç'
            i: 'îïì'
            u: 'ùûü'
            o: 'ôöòõ'
            y: 'ÿ'
            n: 'ñ'
        query = @toLowerCase()
        for letter, list of letters
            list = '[' + letter + list + ']'
            query = query.replace (new RegExp list, 'gi'), if toRegEpx
                list
            else
                letter
        query

    toSearchRegExp: (escape = false) ->
        pattern = splitPattern @, escape
        new RegExp pattern, 'gi'

    toBeginRegExp: (escape = false) ->
        pattern = '^' + splitPattern(@, escape)
        new RegExp pattern, 'gi'

    contains: (needle) ->
        if typeof needle is 'string'
            @indexOf(needle) isnt -1
        else
            needle.test @

    startWith: (needle) ->
        @indexOf(needle) is 0

    endWith: (needle) ->
        @length > needle.length and @substr(-needle.length) is needle

    ucFirst: ->
        if @length
            @[0].toUpperCase() + @.substring 1

    capitalize: ->
        if @length
            @[0].toUpperCase() + @.substring(1).toLowerCase()

safeExtend String.prototype, StringUtils

module.exports = StringUtils
