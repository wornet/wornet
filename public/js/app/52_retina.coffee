mediaQuery = '(-webkit-min-device-pixel-ratio: 1.5), (min--moz-device-pixel-ratio: 1.5), (-o-min-device-pixel-ratio: 3/2), (min-resolution: 1.5dppx)'

if window.devicePixelRatio > 1 or (window.matchMedia and window.matchMedia(mediaQuery).matches)
    $('img').each ->
        $img = $ @
        src = $img.attr 'src'
        if src
            src = src.replace /(\.(png|jpe?g)[^/]*)$/ig, '@2x$1'
            img = new Image()
            img.src = src
            img.onload = ->
                $img.attr 'src', src
