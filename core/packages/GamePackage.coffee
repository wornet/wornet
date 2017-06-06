'use strict'

GamePackage =

    init: (app) ->
        new Promise (resolve) =>
            games = [
                'chess'
            ]
            count = games.length
            for game in games
                @[game](app).then ->
                    unless --count
                        resolve()
                    return
            return

    chess: (app) ->
        Chess = require('chess.js').Chess

        new Promise (gameResolve) ->
            require('momentum-js').connect(app, 'mongodb://localhost:27017/game').then (momentum) ->
                getGameState = (couple, me) ->
                    return new Promise (resolve) ->
                        momentum.count('chessGames_' + couple).then (gamesCount) ->
                            momentum.find('chessMoves_' + couple).then (moves) ->
                                chess = new Chess()
                                moves.forEach (move) ->
                                    chess.move move
                                chess.playingWhite = couple.split('_')[gamesCount % 2] is me
                                chess.whiteTurn = chess.turn() is 'w'
                                chess.myTurn = chess.playingWhite is chess.whiteTurn
                                chess.moves = moves
                                resolve chess

                momentum.setAuthorizationStrategy (mode, method, args, req) ->
                    pieces = args[0].split '_'
                    coupleIds = pieces.slice 1
                    couple = coupleIds.join '_'
                    user = (req.session or {}).user
                    id = (user or {}).hashedId
                    if id and pieces.length is 3 and pieces[0] in ['chessGames', 'chessMoves'] and id in pieces
                        if pieces[0] is 'chessGames'
                            return mode is 'data'

                        if method is 'remove'
                            return new Promise (resolve) ->
                                getGameState(couple, id).then (chess) ->
                                    unless chess.moves.length
                                        resolve false
                                        return
                                    game =
                                        date: new Date()
                                        checkmate: chess.in_checkmate()
                                        draw: chess.in_draw()
                                        stalemate: chess.in_stalemate()
                                        repetition: chess.in_threefold_repetition()
                                        fen: chess.fen()
                                        playingWhite: chess.playingWhite
                                        whiteTurn: chess.whiteTurn
                                        myTurn: chess.myTurn
                                        user: id
                                    collection = 'chessGames_' + couple
                                    momentum.insert(collection, game).then ->
                                        resolve true
                        if method is 'insertOne'
                            delay 500, ->
                                notice =
                                    action: "notice"
                                    author: user.id
                                    notice: [
                                        jd('img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: user) +
                                        jd('span(data-href="/game/chess/' + id + '") ' + s("{username} a joué, à vous !", username: user.name.full))
                                        'chessGameMessage'
                                        user.id
                                    ]
                                adversary = coupleIds
                                    .filter((_id) -> _id isnt id)
                                    .map(cesarRight)
                                NoticePackage.unnotify
                                    action: 'notice'
                                    notice:
                                        type: 'chessGameMessage'
                                        launcher: user.id
                                NoticePackage.notify adversary, null, notice
                        return method in ['find', 'insertOne', 'remove']

                    return false

                gameResolve()
            return

module.exports = GamePackage
