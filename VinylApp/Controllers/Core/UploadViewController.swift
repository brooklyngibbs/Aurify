import UIKit
import SwiftUI
import FirebaseStorage
import Firebase
import FirebaseFirestore

struct SongInfo: Codable {
    var title: String
    var artist: String
    var reason: String
}

struct ImageInfo: Codable {
    var description: String
    var playlistTitle: String
    var music: String?
    var genre: String
    var subgenre: String
    var mood: String
    var songlist: [SongInfo]
}

var completedImage: UIImageView!
var completedLabel: UILabel!
var vinylImage: UIImageView!
var errorImage: UIImageView!


class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - Properties
    
    var stackView: UIStackView!
    
    var selectedImage: UIImage?
    var generatingLabel: UILabel!
    var errorLabel: UILabel!
    
    var labelTexts: [String] = LabelTexts.labelTexts
    
    private var labelTimer: Timer?
    private var labelIndex = 0
    
    var songURIs: [String] = []
    var topArtists: [String] = []
    
    
    private let storage = Storage.storage().reference()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        self.navigationItem.hidesBackButton = true
        
        fetchTopArtists(limit: 10)
        
        errorLabel = UILabel()
        errorLabel.text = "Uh Oh! Something went wrong."
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 2
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = UIFont(name: "Inter-SemiBold", size: 17)
        errorLabel.textColor = AppColors.vampireBlack
        
        errorLabel.preferredMaxLayoutWidth = 250
        errorLabel.isHidden = true
        
        view.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
        ])
        
        errorImage = UIImageView()
        errorImage.image = UIImage(named: "error")
        errorImage.contentMode = .scaleAspectFit
        errorImage.translatesAutoresizingMaskIntoConstraints = false
        errorImage.isHidden = true
        view.addSubview(errorImage)
        
        NSLayoutConstraint.activate([
            errorImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorImage.topAnchor.constraint(equalTo: errorLabel.bottomAnchor),
            errorImage.widthAnchor.constraint(equalToConstant: 200),
            errorImage.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        vinylImage = UIImageView()
        vinylImage.image = UIImage(named: "vinyl3")
        vinylImage.contentMode = .scaleAspectFit
        vinylImage.translatesAutoresizingMaskIntoConstraints = false
        vinylImage.isHidden = true
        view.addSubview(vinylImage)
        
        // Constraints for the custom image view (centered in the view)
        NSLayoutConstraint.activate([
            vinylImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            vinylImage.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            vinylImage.widthAnchor.constraint(equalToConstant: 200), // Adjust width as needed
            vinylImage.heightAnchor.constraint(equalToConstant: 200) // Adjust height as needed
        ])
        
        if let image = selectedImage {
            // Display the selected image
            vinylImage.isHidden = false
            startSpinningAnimation()
            
            // Upload the selected image to Firebase
            uploadSelectedImageToFirebase(image: image)
        }
        
        generatingLabel = UILabel()
        generatingLabel.text = "Generating your picture playlist..."
        generatingLabel.textAlignment = .center
        generatingLabel.numberOfLines = 2
        generatingLabel.translatesAutoresizingMaskIntoConstraints = false
        generatingLabel.font = UIFont(name: "Inter-Light", size: 17)
        generatingLabel.textColor = AppColors.vampireBlack
        
        generatingLabel.preferredMaxLayoutWidth = 250
        
        view.addSubview(generatingLabel)
        
        NSLayoutConstraint.activate([
            generatingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            generatingLabel.topAnchor.constraint(equalTo: vinylImage.bottomAnchor, constant: 20)
        ])
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        // Completed label at the top of the screen
        completedLabel = UILabel()
        completedLabel.text = "Curate your next soundtrack!"
        completedLabel.textAlignment = .center
        completedLabel.numberOfLines = 0
        completedLabel.translatesAutoresizingMaskIntoConstraints = false
        completedLabel.font = UIFont(name: "Outfit-Bold", size: 25)
        completedLabel.textColor = AppColors.vampireBlack
        completedLabel.isHidden = true
        containerView.addSubview(completedLabel)
        
        NSLayoutConstraint.activate([
            completedLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            completedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            completedLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor),
        ])
        
        // Completed image in the middle of the screen
        completedImage = UIImageView()
        completedImage.contentMode = .scaleAspectFit
        completedImage.translatesAutoresizingMaskIntoConstraints = false
        completedImage.isHidden = true
        containerView.addSubview(completedImage)
        
        NSLayoutConstraint.activate([
            completedImage.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            completedImage.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            completedImage.widthAnchor.constraint(equalToConstant: 300),
            completedImage.heightAnchor.constraint(equalToConstant: 300)
        ])
        // Start the timer to update the label text periodically
        startLabelTimer()
    }
    
    func startSpinningAnimation() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = CGFloat.pi * 2.0
        rotationAnimation.duration = 1.0
        rotationAnimation.repeatCount = .greatestFiniteMagnitude
        vinylImage.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    
    func fetchTopArtists(limit: Int) {
        APICaller.shared.getTopArtists(limit: limit) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let artists):
                self.topArtists = artists
                print("Fetched Top Artists: \(self.topArtists)")
                
            case .failure(let error):
                print("Error fetching top artists: \(error)")
            }
        }
    }
    // MARK: - Firebase Function
    
    func sendImageUrlToFirebaseFunction(url: String) {
        guard let functionURL = URL(string: "https://make-scene-api-request-36d3pxwmrq-uc.a.run.app") else {
            print("Invalid Firebase Function URL")
            return
        }
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData = [
            "image_url": url,
            "artists": topArtists
        ] as [String : Any]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestData) {
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        vinylImage.isHidden = true
                        self.generatingLabel.isHidden = true
                        self.errorLabel.isHidden = false
                        errorImage.isHidden = false
                    }
                    print("Error sending data to Firebase Function: \(error.localizedDescription)")
                } else if let data = data {
                    do {
                        if let json = try? JSONDecoder().decode(ImageInfo.self, from: data) {
                            print("Received JSON data:", json)
                            APICaller.shared.createPlaylist(with: json.playlistTitle, description: json.description) { [self] result in
                                switch result {
                                case .success(let playlist):
                                    // Successfully created playlist
                                    let playlistID = playlist.id
                                    savePlaylistToFirestore(playlist: playlist) { result in
                                        switch result {
                                        case .success:
                                            print("Playlist saved to Firestore successfully")
                                        case .failure(let error):
                                            DispatchQueue.main.async {
                                                vinylImage.isHidden = true
                                                self.generatingLabel.isHidden = true
                                                self.errorLabel.isHidden = false
                                                errorImage.isHidden = false
                                            }
                                            print("Failed to save playlist to Firestore:", error)
                                        }
                                    }
                                    convertImageURLToBase64(imageURLString: url) { base64String in
                                        if let base64String = base64String {
                                            APICaller.shared.updatePlaylistImage(imageBase64: base64String, playlistID: playlistID) { updateResult in
                                                switch updateResult {
                                                case .success:
                                                    self.searchAndAppendTrackURIs(songs: json.songlist, playlistID: playlistID)
                                                    //self.addTracksSequentially(to: playlistID, songlist: json.songlist)
                                                    print("Successfully updated playlist image")
                                                case .failure(let error):
                                                    DispatchQueue.main.async {
                                                        vinylImage.isHidden = true
                                                        self.generatingLabel.isHidden = true
                                                        self.errorLabel.isHidden = false
                                                        errorImage.isHidden = false
                                                    }
                                                    print("Failed to update playlist image:", error)
                                                }
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                vinylImage.isHidden = true
                                                self.generatingLabel.isHidden = true
                                                self.errorLabel.isHidden = false
                                                errorImage.isHidden = false
                                            }
                                            print("Failed to convert image URL to base64")
                                        }
                                    }
                                    //print("end")
                                case .failure(let error):
                                    DispatchQueue.main.async {
                                        vinylImage.isHidden = true
                                        self.generatingLabel.isHidden = true
                                        self.errorLabel.isHidden = false
                                        errorImage.isHidden = false
                                    }
                                    print("Failed to create playlist: \(error.localizedDescription)")
                                }
                                
                            }
                        } else {
                            if let jsonString = String(data: data, encoding: .utf8) {
                                print("Invalid JSON Format. Response:", jsonString)
                            } else {
                                print("Invalid JSON Format. Unable to parse response data.")
                            }
                            DispatchQueue.main.async {
                                vinylImage.isHidden = true
                                self.generatingLabel.isHidden = true
                                self.errorLabel.isHidden = false
                                errorImage.isHidden = false
                            }
                        }
                    }
                } else {
                    print("No Data Received")
                    DispatchQueue.main.async {
                        vinylImage.isHidden = true
                        self.generatingLabel.isHidden = true
                        self.errorLabel.isHidden = false
                        errorImage.isHidden = false
                    }
                }
            }
            task.resume()
        }
    }
    
    //MARK: ADD TRACKS
    
    func searchAndAppendTrackURIs(songs: [SongInfo], playlistID: String) {
        APICaller.shared.searchManySongs(q: songs) {results in
            let songURIs = results.compactMap {result in
                switch(result) {
                case .success(let trackURI):
                    return trackURI
                case .failure(_):
                    return nil
                }
            }
            self.addTracksToPlaylist(playlistID: playlistID, songURIs: songURIs)
        }
    }
    
    func addTracksToPlaylist(playlistID: String, songURIs: [String]) {
        // Here you have collected all song URIs in self.songURIs
        // You can now add these tracks to the playlist using the obtained URIs
        APICaller.shared.addTrackArrayToPlaylist(trackURI: songURIs, playlist_id: playlistID) { addResult in
            switch addResult {
            case .success(let playlist):
                print("Successfully added tracks to playlist:", playlist)
                DispatchQueue.main.async {
                    self.updateUI(playlist_id: playlistID)
                }
                // Handle success if needed
            case .failure(let error):
                print("Failed to add tracks to playlist:", error)
                // Handle failure if needed
            }
        }
    }
    
    func addTracksSequentially(to playlistID: String, songlist: [SongInfo], currentIndex: Int = 0) {
        guard currentIndex < songlist.count else {
            // All songs added to the playlist
            print("All songs added to the playlist")
            updateUI(playlist_id: playlistID)
            return
        }
        
        let currentSong = songlist[currentIndex]
        
        APICaller.shared.searchSong(q: currentSong) { result in
            switch result {
            case .success(let trackURI):
                APICaller.shared.addTrackToPlaylist(trackURI: trackURI, playlist_id: playlistID) { addResult in
                    switch addResult {
                    case .success(let playlist):
                        print("Successfully added track \(currentIndex + 1) to playlist:", playlist)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.addTracksSequentially(to: playlistID, songlist: songlist, currentIndex: currentIndex + 1)
                        }
                    case .failure(let error):
                        print("Failed to add track \(currentIndex + 1) to playlist:", error)
                        // Handle the failure to add track to the playlist
                    }
                }
            case .failure(let error):
                print("Failed to get trackURI for song", error)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.addTracksSequentially(to: playlistID, songlist: songlist, currentIndex: currentIndex + 1)
                }
            }
        }
    }
    
    //resize image, call func to put in storage, call func to get playlist
    func uploadSelectedImageToFirebase(image: UIImage) {
        if let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 310, height: 310)),
           let imageData = resizedImage.jpegData(compressionQuality: 1) {
            uploadImageToStorage(imageData: imageData, originalImage: image) { imageUrl in
                guard let imageUrl = imageUrl else {
                    print("Error: Unable to get image URL")
                    return
                }
                
                self.sendImageUrlToFirebaseFunction(url: imageUrl)
            }
        }
    }
    
    //MARK: IMAGE HANDLING
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scale = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    //puts image in storage
    func uploadImageToStorage(imageData: Data, originalImage: UIImage, completion: @escaping (String?) -> Void) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "\(timestamp)_\(UUID().uuidString)"
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let storageRef = self.storage.child("images/\(uniqueFileName).jpeg")
        
        storageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                print("Failed to upload: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url?.absoluteString else {
                    print("Error getting download URL:", error?.localizedDescription ?? "")
                    completion(nil)
                    return
                }
                
                completion(downloadURL)
            }
        }
    }
    
    func convertImageURLToBase64(imageURLString: String, completion: @escaping (String?) -> Void) {
        guard let imageURL = URL(string: imageURLString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: imageURL) { data, response, error in
            guard let imageData = data, error == nil else {
                completion(nil)
                return
            }
            
            let base64String = imageData.base64EncodedString()
            completion(base64String)
        }
        
        task.resume()
    }
    
    //MARK: UPDATE UI
    func updateUI(playlist_id: String) {
        // Hide loading indicator
        vinylImage.isHidden = true
        generatingLabel.isHidden = true
        completedImage.isHidden = false
        completedLabel.isHidden = false
        stopLabelTimer()
        
        APICaller.shared.getPlaylist(with: playlist_id) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let playlist):
                let playlistVC = Playlist2VC(playlist: playlist, userID: UserDefaults.standard.value(forKey: "user_id") as! String)
                DispatchQueue.main.async {
                    let hostingController = UIHostingController(rootView: playlistVC)
                    self.navigationController?.navigationBar.tintColor = UIColor.black
                    self.navigationController?.pushViewController(hostingController, animated: false)
                    self.navigationController?.isNavigationBarHidden = false
                    self.uploadComplete()
                    if let image = UIImage(named: "70s_man") {
                        completedImage.image = image
                        
                        completedImage.layer.cornerRadius = 20
                        completedImage.clipsToBounds = true
                        
                        // dashed border
                        let dashBorder = CAShapeLayer()
                        dashBorder.strokeColor = AppColors.gainsboro.cgColor
                        dashBorder.lineDashPattern = [8, 6] // dash length and gap
                        dashBorder.lineWidth = 5
                        dashBorder.frame = completedImage.bounds
                        dashBorder.fillColor = nil
                        dashBorder.path = UIBezierPath(roundedRect: completedImage.bounds, cornerRadius: 20).cgPath
                        completedImage.layer.addSublayer(dashBorder)
                    } else {
                        DispatchQueue.main.async {
                            vinylImage.isHidden = true
                            self.generatingLabel.isHidden = true
                            self.errorLabel.isHidden = false
                            errorImage.isHidden = false
                        }
                        print("Failed to load image.")
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    vinylImage.isHidden = true
                    self.generatingLabel.isHidden = true
                    self.errorLabel.isHidden = false
                    errorImage.isHidden = false
                }
                print("Failed to fetch playlist:", error)
            }
        }
    }
    
    func savePlaylistToFirestore(playlist: Playlist, completion: @escaping (Result<Void, Error>) -> Void) {
        APICaller.shared.getCurrentUserProfile { result in
            switch result {
            case .success(let userProfile):
                let userID = userProfile.id
                
                // Access Firestore and create a reference to the users collection
                let db = Firestore.firestore()
                let usersCollection = db.collection("users")
                let userDocument = usersCollection.document(userID)
                
                // Prepare the playlist data to be saved in Firestore
                var playlistData: [String: Any] = [
                    "description": playlist.description ?? "",
                    "external_urls": playlist.external_urls ?? [:],
                    "id": playlist.id,
                    "images": playlist.images.map { $0.toDictionary() }, // Convert images array to dictionaries
                    "name": playlist.name,
                    "owner": playlist.owner.toDictionary(), // Convert owner object to dictionary
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
            case .failure(let error):
                DispatchQueue.main.async {
                    vinylImage.isHidden = true
                    self.generatingLabel.isHidden = true
                    self.errorLabel.isHidden = false
                    errorImage.isHidden = false
                }
                print("Failed to get user profile: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func uploadComplete() {
        selectedImage = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func updateGeneratingLabelText() {
        let randomIndex = Int(arc4random_uniform(UInt32(labelTexts.count)))
        generatingLabel.text = labelTexts[randomIndex]
    }
    
    // Function to start the timer
    func startLabelTimer() {
        labelTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(updateGeneratingLabelText), userInfo: nil, repeats: true)
    }
    
    // Function to stop the timer
    func stopLabelTimer() {
        labelTimer?.invalidate()
        labelTimer = nil
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
