do (window, dpr = 'device-pixel-ratio', devicePixelRatio = 'devicePixelRatio') ->

    mediaQuery = '(-webkit-min-' + dpr + ': 1.5), (min--moz-' + dpr + ': 1.5), (-o-min-' + dpr + ': 3/2), (min-resolution: 1.5dppx)'

    if ! window[devicePixelRatio] and (window.matchMedia and window.matchMedia(mediaQuery).matches)
        window[devicePixelRatio] = 2
    if window[devicePixelRatio] > 1
        ratio = if window[devicePixelRatio] is 3
            3
        else
            2
        retinaImages = {}
        load = (img, done) ->
            if img.width
                done()
            else
                img.onload = done
            return
        $.fn.dpr = ->
            $(@).find('img').each ->
                $img = $ @
                src = $img.attr 'src'
                if src and -1 is src.indexOf '@'
                    _src = src.replace /(\.(png|jpe?g)[^/]*)$/ig, '@' + ratio + 'x$1'
                    if 'undefined' isnt typeof retinaImages[src]
                        if retinaImages[src]
                            $img.attr 'src', _src
                    else
                        img = new Image()
                        img.src = _src
                        load img, ->
                            retinaImages[src] = true
                            $img.attr 'src', _src
                            return
                        img.onerror = ->
                            retinaImages[src] = false
                            return
                return
            return
        $document.on 'end-of-load', ->
            $('body').dpr()
    return
