
requirejs.config
    paths: {}


require(['jquery'], () ->

    app =
        initialize: () ->
            alert "Loaded"

    app.initialize()

)
