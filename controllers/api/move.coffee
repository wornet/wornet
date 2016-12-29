'use strict'

module.exports = (router) ->

    if config.wornet.move.enabled and config.wornet.move.api.enabled

        router.put '/add', (req, res) ->

            event = req.body.event
            start = event.startDate
            start = start.split /\//g
            time = (event.startTime.replace('h', ':') + ':00:00').split(/:/g)
            start = start[2] + '-' +
                start[1].replace(/^(.)$/, '0$1') + '-' +
                start[0].replace(/^(.)$/, '0$1') + ' ' +
                time[0].replace(/^(.)$/, '0$1') + ':' +
                time[1].replace(/^(.)$/, '0$1') + ':' +
                time[2].replace(/^(.)$/, '0$1')
            end = event.endDate
            end = end.split /\//g
            time = (event.endTime.replace(/[h:]+/, ':') + ':00:00').split(/:/g)
            end = end[2] + '-' +
                end[1].replace(/^(.)$/, '0$1') + '-' +
                end[0].replace(/^(.)$/, '0$1') + ' ' +
                time[0].replace(/^(.)$/, '0$1') + ':' +
                time[1].replace(/^(.)$/, '0$1') + ':' +
                time[2].replace(/^(.)$/, '0$1')
            delete event.startDate
            delete event.startTime
            delete event.endDate
            delete event.endTime
            event.start = new Date start
            event.end = new Date end
            City.find(name: event.city).limit(1).exec (err, cities) ->
                if err
                    res.serverError err
                    return
                if cities.length is 0
                    res.serverError new PublicError s("Désolé, nous n'avons trouvé aucune ville de ce nom.")
                    return

                city = cities[0]
                event.city = city.id
                event.sector = city.sector
                event.latitude = city.latitude
                event.longitude = city.longitude
                event.latitudeSector = city.latitudeSector
                event.longitudeSector = city.longitudeSector
                Event.create event, (err, event) ->
                    if err
                        res.serverError err
                        return

                    res.publicJson event: event

        router.get '/search/:country/:city/:distance', (req, res) ->

            distance = intval req.params.distance
            if distance > 150000
                res.serverError new PublicError s("150 km maximum")
                return

            where =
                code: req.params.city.accents()
                country: req.params.country.accents()

            City.find(where).limit(1).exec (err, cities) ->

                if err
                    res.serverError err
                    return

                if cities.length is 0
                    res.serverError new PublicError s("Nous n'avons pas trouvé de ville de ce nom.")
                    return

                lat = cities[0].latitude
                long = cities[0].longitude
                GeoPackage.closestEvents lat, long, distance, (err, events) ->
                    if err
                        res.serverError err
                        return

                    if where.country is 'fr'
                        calculs = {}
                        cityIds = events.column 'city'
                        City.find _id: $in: cityIds
                        , (err, cities) ->
                            if err
                                res.serverError err
                                return

                            events.each ->
                                event = @
                                event.city = cities.findOne _id: event.city
                                if event.city
                                    calculs[event.city.name] = (done) ->
                                        cache 'vicopo-' + event.city
                                        , (done) ->
                                            vicopo('http') event.city.name, (err, cities) ->
                                                done if err
                                                    -1
                                                else if cities and cities.length
                                                    cities[0].code
                                                else
                                                    0
                                        , (result) ->
                                            done null, result

                            parallel calculs
                            , (postalCodes) ->
                                events = events.filter (event) ->
                                    if event.city
                                        event.postalCode = postalCodes[event.city.name]
                                    else
                                        true

                                res.publicJson
                                    query: where.country + '/' + where.code
                                    events: events
                            , ->
                                res.publicJson
                                    query: where.country + '/' + where.code
                                    events: events
                            return
                        return

                    res.publicJson
                        query: where.country + '/' + where.code
                        cities: cities
