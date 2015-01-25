'use strict';

var exec;

exec = require("child_process").exec;

function command(commands) {
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
};

command.isProbablyUnix = __dirname.charAt(0) === '/';

command.open = function (url) {
	var program = command.isProbablyUnix ? 'xdg-open' : 'start';
	return command(program + ' ' + url);
};

command.console = function (path) {
	var program = command.isProbablyUnix ? 'console' : 'cmd.exe';
	return command(program);
};

command.sublimetext = function (path) {
	var program = command.isProbablyUnix ? 'sublimetext' : '"C:\\Program Files\\Sublime Text 3\\sublime_text.exe"';
	return command(program + ' ' + path);
};

module.exports = command;
