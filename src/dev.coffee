'use strict'

exec = require("child_process").exec
([
  "coffee -b -o ./ -cw src/"
  "npm start"
]).forEach (command) ->
  child = exec(command)
  child.unref()
  child.stdout.on "data", (data) ->
    console.log data.toString()
  child.stderr.on "data", (data) ->
    error = data.toString()
    if error is "'coffee' n'est pas reconnu en tant que commande interne"
      console.log "Reload after install"
      exec "npm install -g coffee-script"
    console.error error
