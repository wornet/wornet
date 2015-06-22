#!/bin/sh
coffee core/server/init.coffee &
nodemon -e .ejs,.js,.coffee,.jade index.coffee
