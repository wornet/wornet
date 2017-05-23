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
                                resolve chess

                momentum.setAuthorizationStrategy (mode, method, args, req) ->
                    pieces = args[0].split '_'
                    couple = pieces.slice(1).join '_'
                    id = ((req.session or {}).user or {}).hashedId
                    if id and pieces.length is 3 and pieces[0] in ['chessGames', 'chessMoves'] and id in pieces
                        if pieces[0] is 'chessGames'
                            if method is 'updateOne'
                                # if !args[1].pending or args[1].user is id
                                # momentum.count('chessGames_' + couple).then (gamesCount) ->
                                delete args[2].checkmate
                                delete args[2].draw
                                delete args[2].stalemate
                                delete args[2].repetition
                                delete args[2].user

                                return args[1].pending and args[1].user isnt id
                            if method is 'insertOne'
                                return new Promise (resolve) ->
                                    momentum.count('chessGames_' + couple, {pending: true}).then (pendingCount) ->
                                        if pendingCount
                                            resolve false
                                            return
                                            getGameState(couple, id).then (chess) ->
                                                args[1].checkmate = chess.in_checkmate()
                                                args[1].draw = chess.in_draw()
                                                args[1].stalemate = chess.in_stalemate()
                                                args[1].repetition = chess.in_threefold_repetition()
                                                args[1].user = id
                                                args[1].pending = true
                                                resolve true
                            return mode is 'data'

                        if method is 'remove'
                            return new Promise (resolve) ->
                                getGameState(couple, id).then (chess) ->
                                    if chess.in_checkmate() or chess.in_draw() or chess.in_stalemate() or chess.in_threefold_repetition()
                                        if chess.myTurn
                                            return
                                    game =
                                        date: new Date()
                                        abandon: id
                                    collection = 'chessGames_' + couple
                                    momentum.insert(collection, game).then ->
                                        resolve true
                        return method in ['find', 'insertOne', 'remove']

                    return false

                gameResolve()
            return

module.exports = GamePackage
