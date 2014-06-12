'use strict';

var exec = require('child_process').exec;

exec("stylus --watch -c --out public/css lib/styles/*");