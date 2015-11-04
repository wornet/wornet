start .\Redis-x64-2.8.2104\redis-server.exe
start coffee core/server/init.coffee
nodemon -e .ejs,.js,.coffee,.jade index.coffee