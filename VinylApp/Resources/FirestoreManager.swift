import Firebase

class FirestoreManager {
    let db = Firestore.firestore()

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

            let playlistIDs = documents.compactMap { document -> String? in
                let playlistData = document.data()
                return playlistData["id"] as? String
            }

            completion(playlistIDs)
        }
    }
}
