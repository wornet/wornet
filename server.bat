start .\Redis-server\redis-server.exe
start coffee core/server/init.coffee
nodemon -e .ejs,.js,.coffee,.jade index.coffee
