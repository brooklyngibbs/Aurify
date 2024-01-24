import Firebase

class FirestoreManager {
    let db = Firestore.firestore()
    
    func fetchPlaylistIDListener(forUserID userID: String, completion: @escaping ([String]) -> Void) -> ListenerRegistration {
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

            let playlistIDs = documents.compactMap { document -> String? in
                let playlistData = document.data()
                if playlistData["deleted"] as? Bool == true {
                    return nil
                }
                return playlistData["id"] as? String
            }

            completion(playlistIDs)
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
    
    func savePlaylistToFirestore(userID: String, playlist: Playlist, imageUrl: String, imageInfo: ImageInfo) async throws {
        try await withCheckedThrowingContinuation() { continuation in
            savePlaylistToFirestore(userID: userID, playlist: playlist, imageUrl: imageUrl, imageInfo: imageInfo) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func savePlaylistToFirestore(userID: String, playlist: Playlist, imageUrl: String, imageInfo: ImageInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        // Access Firestore and create a reference to the users collection
        let usersCollection = db.collection("users")
        let userDocument = usersCollection.document(userID)
                
        // Prepare the playlist data to be saved in Firestore
        var playlistData: [String: Any] = [
            "description": playlist.description ?? "",
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
            "external_urls": playlist.external_urls ?? [:],
            "id": playlist.id,
            "images": playlist.images.map { $0.toDictionary() },
            "name": playlist.name,
            "owner": playlist.owner.toDictionary(),
            "uri": playlist.uri,
            "isAppGenerated": true
        ]
                
        // Add a timestamp to the playlist data
        playlistData["timestamp"] = FieldValue.serverTimestamp()
                
        // Add a new document to the "playlists" subcollection in the user's document
        userDocument.collection("playlists").document(playlist.id).setData(playlistData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
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
