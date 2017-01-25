module.exports = regularTask 10.minutes, ->
    Invitation.find sended: null, (err, invitations) ->
        if err
            warn err
        else unless empty invitations
            count = config.wornet.limits.mailsAtOnce
            invitations.each ->
                if count--
                    email = @email
                    findById User, @host, (err, user) ->
                        if err
                            war err
                        else if user
                            subject = s("{name} vous invite à rejoindre Wornet", name: user.fullName)
                            signinUrl = config.wornet.protocole +  '://' + (process.env.DEFAULT_HOST or config.wornet.defaultHost)
                            signinUrl += '/user/signin/with/' + encodeURIComponent email
                            message = s("{name} vous invite à rejoindre Wornet, cliquez sur le lien ci-dessous ou copiez-le dans la barre d'adresse de votre navigateur.", name: user.fullName)
                            MailPackage.send email, subject, message + '\n\n' + signinUrl, message + '<br><br><a href="' + signinUrl + '">' + s("Devenir un wornet") + '</a>'
                    @sended = new Date
                    @save()
