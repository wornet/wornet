'use strict'

nodemailer = require 'nodemailer'

errorMessage = 'Mailer not configured or not initialized'

transporter = null

MailPackage =

    init: (options) ->
        fillOptionsWith = (service, user, pass) ->
            options ||=
                service: service
                auth:
                    user: user
                    pass: pass
            if options.service is 'OVH'
                smtpTransport = require 'nodemailer-smtp-transport'
                options = smtpTransport
                    host: 'SSL0.OVH.NET'
                    port: 587
                    auth: options.auth
        if process.env.MAIL_SERVICE
            fillOptionsWith process.env.MAIL_SERVICE, process.env.MAIL_AUTH_USER, process.env.MAIL_AUTH_PASS
        else if config and config.wornet and config.wornet.mail and !empty(config.wornet.mail.auth.user)
            fillOptionsWith config.wornet.mail.service, config.wornet.mail.auth.user, config.wornet.mail.auth.pass
        if options and options.auth and !empty(options.auth.user)
            transporter = nodemailer.createTransport options
        else
            warn errorMessage

    send: (to, subject, text, html = null, from = null, done = null) ->
        if typeof html is 'function'
            if done is null
                done = html
                html = null
            else
                html = html()
        if typeof from is 'function'
            if done is null
                done = from
                from = null
            else
                from = from()

        if html is null
            html = text
            text = html
                .replace /<(br|\/p|\/div)>/g, '\n'
                .replace /<.*?>/g, ''
                .replace /&lt;/g, '<'
                .replace /&gt;/g, '>'
                .replace /&quot;/g, '"'
                .replace /&#039;/g, "'"
                .replace /&amp;/g, '&'
        if from is null
            from = 'Wornet <' + (process.env.WORNET_FROM_EMAIL or 'contact@wornet.net') + '>'

        mailOptions =
            from: from
            to: to
            subject: subject
            text: text
            html: html

        if done is null
            done = (err, info) ->
                if config.wornet.mail.log
                    if err
                        console['log'] ["Send mail failed", mailOptions]
                        warn err
                    else
                        console['log'] ["Send mail succeed", mailOptions]
                        log JSON.stringify(info) if info

        if transporter is null
            throw new Error errorMessage

        @exec mailOptions, done

    exec: (mailOptions, done) ->
        transporter.sendMail mailOptions, done

module.exports = MailPackage
