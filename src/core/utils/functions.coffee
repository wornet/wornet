'use strict'

module.exports =
    intval: (n) ->
        n = parseInt(n)
        isNaN(n) ? 0 : n
    ,
    trim: (str) ->
        str.replace(/^\s+/g, '').replace(/\s+$/g, '')
    ,
    empty: (value) ->
        type = typeof(value)
        (
            type is 'undefined' ||
            value is null ||
            value is false ||
            value is 0 ||
            value is "0" ||
            value is "" || (
                type is 'object' && (
                    (
                        typeof(value.length) not 'undefined' &&
                        value.length is 0
                    ) || (
                        typeof(value.length) is 'undefined' &&
                        typeof(JSON) is 'object' &&
                        typeof(JSON.stringify) is 'function' &&
                        JSON.stringify(b) is '{}'
                    )
                )
            )
        )
    ,
    s: (val) ->
        val
    ,
    lang: () ->
        "fr"