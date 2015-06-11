'use strict';

var exec, child, output;

process.chdir(__dirname  + '/..');

exec = require("child_process").exec;

child = exec("npm test");
child.unref();

output = '';

function next(data) {
	output += data;
	if(~data.indexOf('passing')) {
		setTimeout(function () {
			var fail, success;
			fail = 0;
			success = 0;
			output.replace(/\s([0-9]+)\s+passing/g, function (all, passing) {
				success = passing | 0;
			});
			output.replace(/\s([0-9]+)\s+failing/g, function (all, failing) {
				fail = failing | 0;
			});
			console.log(Math.floor(100 * success / Math.max(1, fail + success)) + '%');
			process.exit();
		}, 500);
	}
}

child.stdout.on("data", function(data) {
	next(data);
});
child.stderr.on("data", function(data) {
	next(data);
});
