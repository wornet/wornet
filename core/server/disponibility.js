'use strict';

var PORT, SERVICE, exec;
PORT = (process.env.PORT || 8002);
SERVICE = (process.env.SERVICE || 'wornetint');
exec = require("child_process").exec;

exec('wget -qO- http://localhost:' + PORT + '/status', function (err, data, errm) {
    if(data !== 'OK') {
        var cmd = 'service ' + SERVICE + ' restart';
        console.log(cmd);
        exec(cmd, function (err, data, errm) {
            console.log(data);
        });
    }
});
