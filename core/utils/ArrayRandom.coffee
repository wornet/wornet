'use strict'
###
Extend Array prototype
###

RandomArray =
    ###
    Get a random index from 0 to the length of the array - 1
    @return integer index
    ###
    randomIndex: ->
        Math.floor Math.random() * @length

    ###
    Pick random values from an array
    @param int count : number of values
    @return array list of values if count is specified
    @return mixed a unique value if count isn't specified
    ###
    pick: (count = 0) ->
        count = intval count
        if count < 1
            @[@randomIndex()]
        else
            (@pick() for [1..count])

    ###
    Pick a random value and remove it from an array
    @param int count : number of values
    @return array list of values if count is specified
    @return mixed a unique value if count isn't specified
    ###
    pickAndShift: (count = 0) ->
        count = intval count
        if count < 1
            index = @randomIndex()
            value = @[index]
            others = @filter (val, i) ->
                i isnt index
            for [1..@length]
                @shift()
            arr = @
            others.forEach (val) ->
                arr.push val
            value
        else
            (@pickAndShift() for [1..count])

    ###
    Shuffle an array
    @return shuffled array
    ###
    shuffle: ->
        arr = @slice()
        i = @length
        while i
            j = Math.floor Math.random() * i
            val = arr[--i]
            arr[i] = arr[j]
            arr[j] = val
        arr

    ###
    Pick random values from an array (but not twice the same)
    @param int count : number of values
    @return array list of values if count is specified
    @return mixed a unique value if count isn't specified
    ###
    pickUnique: (count = 0) ->
        count = intval count
        if count < 1
            @pick()
        else if count < @length
            @pickAndShift count
        else
            @shuffle()

safeExtend Array.prototype, RandomArray

module.exports = RandomArray
