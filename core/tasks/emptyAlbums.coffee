emptyAlbumsTask =

	checkForEmptyAlbums:  ->
		today = new Date()
		aWeekEarlier = today.subDays 7
		where =
			lastEmpty: $lt: aWeekEarlier
		Album.find where, (e, albums) ->
			for album in albums
				wherePhoto =
					album: album._id
					status: "published"
				Photo.find wherePhoto, (e, photos) ->
					if !photos || photos.length is 0
						emptyAlbumsTask.removeAlbum album

	removeAlbum: (album) ->
		id= album._id
		Album.remove
			_id: id
		, (e) ->
			Status.update
				album: id
			,
				album: null
			, (e) ->


setInterval emptyAlbumsTask.checkForEmptyAlbums, 1.day
#setInterval emptyAlbumsTask.checkForEmptyAlbums, 10000

module.exports = emptyAlbumsTask
