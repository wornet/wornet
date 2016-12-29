'use strict'

simpleText = '[^><&\\n\\r\"]+'
emailPattern = '[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.+_-]+\\.[a-zA-Z]{2,}'

RegExpString =

    simpleText: simpleText
    fullname: simpleText + '(\\s' + simpleText + ')+'
    phone: '(\\+\\d+(\\s|-))?0\\d(\\s|-)?(\\d{2}(\\s|-)?){4}'
    email: emailPattern
    emailMultiple: emailPattern + '(\\s*,\\s*' + emailPattern + ')*'

    get: (name) ->
        name = name.replace /-([a-z])/g, (m) -> m[1].toUpperCase()
        @[name]

    is: (name) ->
        '^' + @get(name) + '$'

    trim: (name) ->
        '^\\s*' + @get(name) + '\\s*$'

RegExp.get = (name) ->
    new RegExp(RegExpString.get name, 'g')

RegExp.is = (name) ->
    new RegExp(RegExpString.is name, 'g')

RegExp.trim = (name) ->
    new RegExp(RegExpString.trim name, 'g')

module.exports = RegExpString