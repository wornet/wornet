
fs = require 'fs'
command = require __dirname + '/../system/command.js'

process.chdir __dirname + '/../..'

fs.exists 'mongod.lnk', (exists) ->
    if exists
        command 'mongod.lnk'

# Build coffee scripts
coffee = fs.realpathSync __dirname + '/../../node_modules/.bin/coffee'
if process.env.NODE_ENV is 'production'
    command coffee + ' -bc -o public/js --join app public/js/app/'
else
    command coffee + ' -bcw -o public/js --join app public/js/app/'
    command coffee + ' -bcw -o public/js --join test public/js/test/'
