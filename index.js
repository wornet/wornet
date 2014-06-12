'use strict';


var kraken = require('kraken-js'),
    extend = require('extend'),
    app = require('express')(),
    options = {
        onconfig: function (config, next) {
            //any config setup/overrides here
            next(null, config);
        }
    },
    port = process.env.PORT || 8000;


app.use(kraken(options));


extend(app.locals, {
    s: function(val){
        return val;
    },
    lang: function () {
        return "fr";
    }
});


app.listen(port, function (err) {
    console.log('[%s] Listening on http://localhost:%d', app.settings.env, port);
});