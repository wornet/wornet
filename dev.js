'use strict';

var exec = require('child_process').exec;

([
	"coffee -o public/js -cw public/coffee",
	"npm start"
]).forEach(function (command) {
	var child = exec(command);
	child.unref();
	child.stdout.on('data', function(data) {
		console.log(data.toString());
	})
});