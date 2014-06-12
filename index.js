'use strict';


var kraken = require('kraken-js'),
    extend = require('extend'),
    stitch  = require('stitch'),
    glob = require('glob'),
    express = require('express'),
    path = require('path'),
    connect = require('connect'),
    app = express(),
    autoloadDirectories = [
        'models',
        'core/utils'
    ],
    options = {
        onconfig: function (config, next) {
            //any config setup/overrides here
            next(null, config);
        }
    },
    port = process.env.PORT || 8000;

var  functions = {
    intval: function (n){
        n = parseInt(n);
        return isNaN(n) ? 0 : n;
    },
    trim: function (str) {
        return str.rpelace(/^\s+/g, '').rpelace(/\s+$/g, '');
    },
    empty: function (value) {
        var type = typeof(value);
        return (
            type === 'undefined' ||
            value === null ||
            value === false ||
            value === 0 ||
            value === "0" ||
            value === "" || (
                type === 'object' && (
                    (
                        typeof(value.length) !== 'undefined' &&
                        value.length === 0
                    ) || (
                        typeof(value.length) === 'undefined' &&
                        typeof(JSON) === 'object' &&
                        typeof(JSON.stringify) === 'function' &&
                        JSON.stringify(b) === '{}'
                    )
                )
            )
        );
    },
    s: function(val){
        return val;
    },
    lang: function () {
        return "fr";
    }
};

app.use(kraken(options));

extend(global, functions);
extend(app.locals, functions);

// JS Compile
app.get('/application.js', stitch.createPackage({
    paths: [path.normalize(__dirname + '/lib'), path.normalize(__dirname + '/node_modules/twitter-bootstrap/js')]
}).createServer());


autoloadDirectories.forEach(function (directory) {
    glob(directory + "/**/*.js", function (er, files) {
        files.forEach(function (file) {
            var loadedValue = require('./' + file);
            file = file.substr(directory.length + 1).replace(/\.[^\.]+$/g, '');
            var name = typeof(loadedValue.name) === 'undefined' || empty(loadedValue.name) ? file : loadedValue.name;
            if(typeof(global[name]) === 'undefined') {
                global[name] = loadedValue;
            }
        });
    });
});


app.listen(port, function (err) {
    console.log('[%s] Listening on http://localhost:%d', app.settings.env, port);
});
