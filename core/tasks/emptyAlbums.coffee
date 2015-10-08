emptyAlbumsTask =

	checkForEmptyAlbums:  ->
		today = new Date()
		aWeekEarlier = today.subDays 7
		whereUser =
			$or: [
				photoAlbumId: $ne: null
			,
				sharedAlbumId: $ne: null
			]
		exceptions = []
		User.find whereUser
			.select 'photoAlbumId sharedAlbumId'
			.exec (err, users) ->
				for user in users
					if user.photoAlbumId
						exceptions.push user.photoAlbumId
					if user.sharedAlbumId
						exceptions.push user.sharedAlbumId
				where =
					lastEmpty: $lt: aWeekEarlier
					_id: $nin: exceptions
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


setInterval emptyAlbumsTask.checkForEmptyAlbums, 1.hour

module.exports = emptyAlbumsTask
