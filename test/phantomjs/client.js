var page = require('webpage').create();
page.open('http://localhost:8000/test', function () {
	var title = page.evaluate(function () {
		return document.title;
	});
	console.log(title);
	phantom.exit();
});