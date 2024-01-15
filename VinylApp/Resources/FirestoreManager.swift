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
                return playlistData["id"] as? String
            }

            completion(playlistIDs)
        }
        
        return listener
    }

    func fetchPlaylistIDs(forUserID userID: String, completion: @escaping ([String]) -> Void) {
        print("Fetching playlist IDs for user ID:", userID)
        
        let userDocumentRef = db.collection("users").document(userID).collection("playlists")

        userDocumentRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching user playlists: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No playlist documents found for the user")
                completion([])
                return
            }

            let sortedDocs = documents.sorted { a, b in
                if let tsa = a.data()["timestamp"] as? Timestamp {
                    if let tsb = b.data()["timestamp"] as? Timestamp {
                        return tsa.dateValue() > tsb.dateValue()
                    }
                }
                return true
            }

            let playlistIDs = sortedDocs.compactMap { document -> String? in
                let playlistData = document.data()
                return playlistData["id"] as? String
            }

            completion(playlistIDs)
        }
    }
}
