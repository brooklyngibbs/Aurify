import Firebase

class FirestoreManager {
    let db = Firestore.firestore()
    
    func fetchPlaylistIdForDocument(forUserID userID: String, firestorePlaylistId: String) async throws -> String? {
        let playlistId = try await db.collection("users").document(userID).collection("playlists").document(firestorePlaylistId).getDocument()
        return playlistId.data()?["spotify_id"] as? String
    }
    
    func fetchPlaylistIDListener(forUserID userID: String, completion: @escaping ([FirebasePlaylist]) -> Void) -> ListenerRegistration {
        let listener = db.collection("users").document(userID).collection("playlists").order(by: "timestamp", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching user playlists: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                print("No playlist documents found for the user")
                completion([])
                return
            }

            let playlists = documents.compactMap { document -> FirebasePlaylist? in
                if let playlist = try? document.data(as: FirebasePlaylist.self) {
                    if playlist.deleted ?? false {
                        return nil
                    }
                    return playlist
                }
                print("Could not convert: \(String(describing: document.data()["id"]))")
                return nil
            }

            completion(playlists)
        }
        
        return listener
    }

    func fetchPlaylistCount(forUserID userID: String, completion: @escaping (Result<Int, Error>) -> Void) {
        print("Fetching playlist IDs for user ID:", userID)
        
        let userDocumentRef = db.collection("users").document(userID).collection("playlists")

        userDocumentRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching user playlists: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            completion(.success(querySnapshot?.count ?? 0))
        }
    }
    
    func fetchLikedStatus(forUserID userID: String, playlistID: String, completion: @escaping (Bool?, Error?) -> Void) {
        let userPlaylistRef = db.collection("users").document(userID).collection("playlists").document(playlistID)

        userPlaylistRef.getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }

            if let data = snapshot?.data(), let liked = data["liked"] as? Bool {
                completion(liked, nil)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func savePlaylistToFirestore(userID: String, name: String, description: String, songInfo: [CleanSongInfo], imageUrl: String, imageInfo: ImageInfo) async throws -> String {
        return try await withCheckedThrowingContinuation() { continuation in
            savePlaylistToFirestore(userID: userID, name: name, description: description, songInfo: songInfo, imageUrl: imageUrl, imageInfo: imageInfo) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func savePlaylistToFirestore(userID: String, name: String, description: String, songInfo: [CleanSongInfo], imageUrl: String, imageInfo: ImageInfo, completion: @escaping (Result<String, Error>) -> Void) {
        // Access Firestore and create a reference to the users collection
        let usersCollection = db.collection("users")
        let userDocument = usersCollection.document(userID)
                
        let docRef = userDocument.collection("playlists").document()
        let docId = docRef.documentID
        // Prepare the playlist data to be saved in Firestore
        var playlistData: [String: Any] = [
            "description": description,
            "cover_image_url": imageUrl,
            "image_info": [
                "description": imageInfo.description,
                "music": imageInfo.music ?? "",
                "genre": imageInfo.genre,
                "subgenre": imageInfo.subgenre,
                "mood": imageInfo.mood,
                "songs": imageInfo.songlist.map { song in
                    return [
                        "artist": song.artist,
                        "title": song.title,
                        "reason": song.reason
                    ]
                }
            ],
            "playlist_info": songInfo.map { song in
                return [
                    "artist": song.artistName,
                    "title": song.title,
                    "uri": song.spotifyUri,
                    "preview_url": song.previewUrl,
                    "cover_image_url": song.artworkUrl,
                ]
            },
            "id": docId,
            "spotify_id": "",
            "images": songInfo.map {$0.artworkUrl },
            "name": name,
            "isAppGenerated": true,
            "external_urls": [:],
        ]
                
        // Add a timestamp to the playlist data
        playlistData["timestamp"] = FieldValue.serverTimestamp()
                
        // Add a new document to the "playlists" subcollection in the user's document
        docRef.setData(playlistData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success((docId)))
            }
        }
    }
    
    func updateFirestoreWithSpotify(userId: String, fsPlaylist: FirebasePlaylist, spPlaylist: Playlist) async throws {
        let usersCollection = db.collection("users")
        let userDocument = usersCollection.document(userId)
                
        let docRef = userDocument.collection("playlists").document(fsPlaylist.playlistId)
        print("Spotify id: \(spPlaylist.id)")
        print("Playlist id: \(fsPlaylist.playlistId)")
        let externalUrls = spPlaylist.externalUrls ?? [:]
        let appGenerated = spPlaylist.isAppGenerated ?? true
        let timestamp = spPlaylist.timestamp ?? Timestamp.init()
        try await docRef.updateData(["spotify_id": spPlaylist.id,
                                     "external_urls": externalUrls,
                                     "isAppGenerated": appGenerated,
                                     "timestamp": timestamp])
    }
}

extension APIImage {
    func toDictionary() -> [String: Any] {
        var imageDictionary: [String: Any] = [:]
        imageDictionary["url"] = self.url
        
        return imageDictionary
    }
}

extension User {
    func toDictionary() -> [String: Any] {
        var userDictionary: [String: Any] = [:]
        userDictionary["id"] = self.id
        return userDictionary
    }
}
