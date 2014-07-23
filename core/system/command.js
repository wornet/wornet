'use strict';

var exec;

exec = require("child_process").exec;

module.exports = function command(commands) {
	if(typeof(commands) === 'string')
		commands = Array.prototype.slice.call(arguments);
	else if(!Array.isArray(commands))
		return console.error('TypeError: command called on non-array and non-string');
	commands.forEach(function(command) {
		var child;
		child = exec(command);
		child.unref();
		child.stdout.on("data", function(data) {
			console.log(data.toString());
		});
		child.stderr.on("data", function(data) {
			console.error(data.toString());
		});
	});
}
