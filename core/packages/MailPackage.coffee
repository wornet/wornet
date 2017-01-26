'use strict'

nodemailer = require 'nodemailer'

errorMessage = 'Mailer not configured or not initialized'

transporter = null

MailPackage =

    init: (options) ->
        if process.env.MAIL_SERVICE
            options ||=
                service: process.env.MAIL_SERVICE
                auth:
                    user: process.env.MAIL_AUTH_USER
                    pass: process.env.MAIL_AUTH_PASS
            transporter = nodemailer.createTransport options
        else if empty(config) or empty(config.wornet) or empty(config.wornet.mail) or empty(config.wornet.mail.auth.user)
            warn errorMessage
        else
            options ||=
                service: config.wornet.mail.service
                auth:
                    user: config.wornet.mail.auth.user
                    pass: config.wornet.mail.auth.pass
            if options.service is 'OVH'
                smtpTransport = require 'nodemailer-smtp-transport'
                options = smtpTransport
                    host: 'SSL0.OVH.NET'
                    port: 587
                    auth: options.auth
            transporter = nodemailer.createTransport options

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
