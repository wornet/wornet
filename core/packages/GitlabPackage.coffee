'use strict'

logging = require 'gitlab-logging'

pack = require __dirname + '/../../package.json'

host = process.env.GITLAB_HOST

head = 'master'

fs.readFile __dirname + '/../../.git/HEAD', (err, contents) ->
    if contents
        contents = '' + contents
        unless contents.contains 'refs/heads/master'
            head = contents

if host
    logging.configure
        host: host
        user: 'autoreporter'
        token: process.env.GITLAB_TOKEN
        project_id: 3
        assignee_id: 2
        environment: config.wornet.env || 'production'

errors = {}

GitlabPackage =
    format: (error) ->
        (pack.version || config.wornet.version) + ': ' + error + '\n```\n' +
        strval (error.stack || (new Error).stack)
            .replace(/```/g, '')
            .replace(/\n  /g, '\n- ')
            .replace(
                /(\/home\/[^\/]+\/((preprod|prod|production|stagging)\/)?([^:]+):([0-9]+)):/g,
                (all, path, _, env, file, line) ->
                    repository = process.env.GITLAB_NAMESPACE + '/' + process.env.GITLAB_PROJECT
                    '[' + path + '](' + host + '/' + repository + '/blob/' + head + '/' + file + '#L' + line + '):'
            )
    enabled: ->
        config.env.production and host
    issue: (error) ->
        if GitlabPackage.enabled()
            logging.handle GitlabPackage.format error
            #console['log'] "Error issued:"
            #console['warn'] error
    error: (error) ->
        if GitlabPackage.enabled()
            error = GitlabPackage.format error
            code = sha1 error
            if errors[code]
                for err, k of errors[code]
                    if k < Date.yesterday().getTime()
                        delete errors[code]
            else
                errors[code] = {}
            errors[code][time()] = error
            # if errors[code].getLength() is config.wornet.errorsToIssue
            GitlabPackage.issue error
            #console['log'] "Error recorded:"
            #console['warn'] error

module.exports = GitlabPackage
