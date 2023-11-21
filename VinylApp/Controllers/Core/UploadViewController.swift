import UIKit
import FirebaseStorage
import Firebase



class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    //MARK: - Properties
    
    var imageView: UIImageView!
    var uploadButton: UIButton!
    var stackView: UIStackView!

    private let storage = Storage.storage().reference()
    var descriptionText: String = ""
    var playlistNameText: String = ""
    var genreText: String = ""
    var songText: String = ""
    var songList: [String] = []
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        

        let configuration = UIImage.SymbolConfiguration(pointSize: 80, weight: .medium)
        let plusImage = UIImage(systemName: "plus", withConfiguration: configuration)

        imageView = UIImageView(image: plusImage)
        // Change the color of the plus sign
        imageView.tintColor = UIColor(red: 0xB8/255.0, green: 0xD0/255.0, blue: 0xEB/255.0, alpha: 1.0)
        imageView.contentMode = .center
        imageView.layer.borderWidth = 2.0
        imageView.layer.borderColor = UIColor(red: 0xB8/255.0, green: 0xD0/255.0, blue: 0xEB/255.0, alpha: 1.0).cgColor
        imageView.layer.cornerRadius = 10.0
        imageView.backgroundColor = .clear

        uploadButton = UIButton()
        uploadButton.setTitle("Upload", for: .normal)
        uploadButton.backgroundColor = UIColor(red: 0xB8/255.0, green: 0xD0/255.0, blue: 0xEB/255.0, alpha: 1.0)
        uploadButton.layer.cornerRadius = 10.0
        uploadButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        uploadButton.frame = CGRect(x: 0, y: 0, width: 100, height: 40)

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .center
        verticalStackView.spacing = 50
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false

        verticalStackView.addArrangedSubview(imageView)
        verticalStackView.addArrangedSubview(uploadButton)

        view.addSubview(verticalStackView)

        NSLayoutConstraint.activate([
            verticalStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verticalStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            uploadButton.widthAnchor.constraint(equalToConstant: 100),
            imageView.widthAnchor.constraint(equalToConstant: 300),
            imageView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    // MARK: - Button Action

    @IBAction func didTapButton() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
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

        let requestData = ["image_url": url]
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestData) {
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending data to Firebase Function: \(error.localizedDescription)")
                } else if let data = data {
                    do {
                        //print("Data = \(String(decoding: data, as: UTF8.self))")
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("Received JSON data:", json)
                            if let description = json["Description"] as? String {
                                self.descriptionText = description
                            }
                            if let openaiMessage = json["OpenAI Message"] as? String {
                                self.playlistNameText = openaiMessage
                            }
                            if let genreMessage = json["Genre Message"] as? String {
                                self.genreText = genreMessage
                            }
                            if let songMessage = json["Song Message"] as? String {
                                self.songText = songMessage
                                self.songList = songMessage.components(separatedBy: "\n").compactMap { line in
                                    let cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    // Regex pattern to match "Song" by "Artist" format
                                    let pattern = #""(.*)" by (.*[^"])$"#  // Matches "Song" by "Artist"
                                    
                                    if let range = cleanedLine.range(of: pattern, options: .regularExpression) {
                                        let matchedString = cleanedLine[range]
                                        let extractedSong = String(matchedString.dropFirst().dropLast())
                                        return extractedSong
                                    } else {
                                        return nil // Discard lines that don't match the expected format
                                    }
                                }

                                APICaller.shared.createPlaylist(with: self.playlistNameText, description: self.descriptionText) { [self] result in
                                    switch result {
                                    case .success(let playlist):
                                        // Successfully created playlist
                                        let playlistID = playlist.id
                                        print("playlistID: \(playlistID)")

                                        convertImageURLToBase64(imageURLString: url) { base64String in
                                            if let base64String = base64String {
                                                APICaller.shared.updatePlaylistImage(imageBase64: base64String, playlistID: playlistID) { updateResult in
                                                    switch updateResult {
                                                    case .success:
                                                        addTracksSequentially(to: playlistID, songs: songList)
                                                        print("Successfully updated playlist image")
                                                    case .failure(let error):
                                                        print("Failed to update playlist image:", error)
                                                    }
                                                }
                                            } else {
                                                print("Failed to convert image URL to base64")
                                            }
                                        }
                                        //print("end")
                                    case .failure(let error):
                                        print("Failed to create playlist:", error)
                                    }
                                }
                            }
                        } else {
                            print("Invalid JSON Format")
                            // Handle the case where the response is not valid JSON
                        }
                    } catch {
                        print("Error parsing JSON: \(error.localizedDescription). Data = \(String(decoding: data, as: UTF8.self))")
                        // Handle the case where an error occurred during JSON parsing
                    }
                } else {
                    print("No Data Received")
                    // Handle the case where no data was received in the response
                }
            }
            task.resume()
        }
    }
    
    func addTracksSequentially(to playlistID: String, songs: [String], currentIndex: Int = 0) {
        guard currentIndex < songs.count else {
            // All songs added to the playlist
            print("All songs added to the playlist")
            return
        }

        let currentSong = songs[currentIndex]
        let formattedSong = currentSong.trimmingCharacters(in: .whitespacesAndNewlines)

        APICaller.shared.searchSong(q: formattedSong, playlist_id: playlistID) { result in
            switch result {
            case .success(let trackURI):
                APICaller.shared.addTrackToPlaylist(trackURI: trackURI, playlist_id: playlistID) { addResult in
                    switch addResult {
                    case .success(let playlist):
                        print("Successfully added track \(currentIndex + 1) to playlist:", playlist)
                        // Recursively call the function for the next song after a delay (or use a completion handler of addTrackToPlaylist)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.addTracksSequentially(to: playlistID, songs: songs, currentIndex: currentIndex + 1)
                        }
                    case .failure(let error):
                        print("Failed to add track \(currentIndex + 1) to playlist:", error)
                        // Handle the failure to add track to the playlist
                    }
                }
            case .failure(let error):
                print("Failed to get trackURI for song \(formattedSong):", error)
                // Handle the failure to get trackURI here
                // Move to the next song after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.addTracksSequentially(to: playlistID, songs: songs, currentIndex: currentIndex + 1)
                }
            }
        }
    }
    
    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.editedImage] as? UIImage {
            if let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 300, height: 300)),
               let imageData = resizedImage.jpegData(compressionQuality: 1) {
                uploadImageToFirebase(imageData: imageData, originalImage: image) { imageUrl in
                    guard let imageUrl = imageUrl else {
                        print("Error: Unable to get image URL")
                        return
                    }
                    
                    // URL is available, proceed with further steps
                    self.sendImageUrlToFirebaseFunction(url: imageUrl)
                    DispatchQueue.main.async {
                        self.imageView.image = resizedImage
                        self.imageView.contentMode = .scaleAspectFill
                        self.imageView.clipsToBounds = true
                        self.imageView.layer.cornerRadius = 10.0
                        self.uploadButton.backgroundColor = .gray
                        
                    }
                }
            }
        }
    }


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

    func uploadImageToFirebase(imageData: Data, originalImage: UIImage, completion: @escaping (String?) -> Void) {
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

            // Get the modified filename from the metadata
            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url?.absoluteString else {
                    print("Error getting download URL:", error?.localizedDescription ?? "")
                    completion(nil)
                    return
                }
                
                print("Download URL:", downloadURL)
                DispatchQueue.main.async {
                    self.imageView.image = originalImage
                }
                
                // Pass the URL to the completion handler
                completion(downloadURL)
            }
        }
    }



    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
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



}
