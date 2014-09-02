var HOST, SERVICE, exec;
HOST = (process.env.HOST || 'int.wornet.com');
SERVICE = (process.env.SERVICE || 'wornetint');
exec = require("child_process").exec;

exec('wget http://' + HOST + '/git-status', function (err, data, errm) {
	console.log([err, data, errm]);
	if(data !== 'OK') {
		var cmd = 'service ' + SERVICE + ' update';
		console.log(cmd);
		exec(cmd, function (err, data, errm) {
			console.log(data);
		});
	}
});
