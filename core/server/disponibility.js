var PORT, SERVICE, exec;
PORT = (process.env.PORT || 8002);
SERVICE = (process.env.SERVICE || 'wornetint');
exec = require("child_process").exec;

exec('wget -qO- http://localhost:' + PORT + '/git-status', function (err, data, errm) {
	console.log([err, data, errm]);
	if(data !== 'OK') {
		var cmd = 'service ' + SERVICE + ' update';
		console.log(cmd);
		exec(cmd, function (err, data, errm) {
			console.log(data);
		});
	}
});
