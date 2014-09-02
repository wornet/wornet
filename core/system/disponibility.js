var HOST, SERVICE command;
HOST = (process.env.HOST || 'int.wornet.com');
SERVICE = (process.env.SERVICE || 'wornetint');
exec = require("child_process").exec;

exec('wget http://' + HOST + '/git-status', function (err, data, errm) {
	if(data !== 'OK') {
		exec('service ' + SERVICE + ' update');
	}
});
