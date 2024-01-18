import SwiftUI
import Combine
import Firebase
import FirebaseStorage

struct LibraryView: View {
    @State private var playlists : [Playlist] = []
    @State private var listener : ListenerRegistration?
    @State private var isLoading = true // Track loading state
    
    @State private var displayName: String = ""
    @State private var userID: String = ""
    
    @State private var showingSettings = false
    @State private var userProfileImage: UIImage?
    
    var body: some View {
        ZStack {
            if isLoading {
                // loading circle
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .tint(Color(AppColors.vampireBlack))
            } else {
                NavigationView {
                    VStack(alignment: .leading, spacing: 10) {
                        CustomTitleView()
                            .padding(.top, 28.5)
                        
                        ScrollView {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(Color(AppColors.moonstoneBlue))
                                    .cornerRadius(20)
                                    .padding(.bottom, 25)
                                    .padding(.horizontal, 5)
                                
                                if let userProfileImage = userProfileImage {
//MARK: PROFILE VIEW
                                    GeometryReader { geometry in
                                        VStack(alignment: .center, spacing: 10) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 100, height: 100)
                                                    .shadow(color: .white.opacity(1.0), radius: 7, x: 0, y: 0)
                                                
                                                Image(uiImage: userProfileImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                            }
                                            Text(displayName)
                                                .foregroundColor(.white)
                                                .font(.custom("Outfit-Bold", size: 16))
                                                .padding(.top, 5)
                                            .padding(.bottom, 20)
                                            
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(.horizontal)
                                        .overlay(
                                            Button(action: {
                                                showingSettings = true
                                            }) {
                                                Image(systemName: "ellipsis")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 15))
                                                    .padding(10)
                                            }
                                                .offset(x: geometry.size.width / 2 - 30, y: -geometry.size.height / 2 + 20)
                                            
                                                .sheet(isPresented: $showingSettings) {
                                                    NavigationView {
                                                        SettingsViewController(userProfileImage: $userProfileImage, userName: self.displayName, userID: self.userID)
                                                            .navigationBarTitle("Settings")
                                                    }
                                                }
                                        )
                                    }
                                }
                            }
                            .frame(height: 220)
                            .padding()
//MARK: PLAYLIST VIEW
                            if playlists.isEmpty {
                                VStack {
                                    Spacer()
                                    Text("Uh oh!")
                                        .padding(.bottom, 10)
                                        .font(.custom("Outfit-Bold", size: 30))
                                    Text("No playlists yet.")
                                        .font(.custom("Inter-Light", size: 18))
                                    Spacer()
                                }
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(playlists.indices, id: \.self) { index in
                                        NavigationLink(destination: Playlist2VC(playlist: playlists[index], userID: userID)) {
                                            PlaylistCellView(playlist: playlists[index])
                                                .padding(.bottom, 20)
                                                .id(UUID()) // Ensure each view has a unique ID
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true) // Hide the navigation bar
        .accentColor(Color(AppColors.vampireBlack))
        .task {
            fetchProfile() { userID in
                listener?.remove()
                listener = FirestoreManager().fetchPlaylistIDListener(forUserID: userID) { playlistIDs in
                    fetchDataForPlaylistIDs(playlistIDs: playlistIDs) {
                        isLoading = false
                    }
                }
            }
        }
        .onDisappear() {
            listener?.remove()
            listener = nil
        }
    }
    
    func fetchDataForPlaylistIDs(playlistIDs : [String], completion: @escaping () -> Void) {
        var tempPlaylists = [Playlist?](repeating:nil, count: playlistIDs.count)
        let dispatchGroup = DispatchGroup()
        for (index, playlistID) in playlistIDs.enumerated() {
            dispatchGroup.enter()
            APICaller.shared.getPlaylist(with: playlistID) { result in
                switch result {
                case .success(let playlist):
                    tempPlaylists[index] = playlist
                    //tempPlaylists.insert(playlist, at: index)
                case .failure(let error):
                    print("Failed to fetch playlist: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            self.playlists = tempPlaylists.compactMap{ $0 }
            completion()
        }
    }

    //MARK: PROFILE FUNCTIONS
    private func fetchProfile(_ completion: @escaping (String) -> Void) {
        APICaller.shared.getCurrentUserProfile { [self] result in
            switch result {
                case .success(let userProfile):
                    DispatchQueue.main.async {
                        self.userID = userProfile.id
                        self.displayName = userProfile.display_name
                    }
                    
                checkProfileImageInStorage(userID: userProfile.id) { profileImageExists in
                        if profileImageExists {
                            loadProfileImageFromStorage(userID: userProfile.id)
                        } else {
                            if let lastImageURLString = userProfile.images.last?.url,
                               let lastImageURL = URL(string: lastImageURLString) {
                                loadImage(from: lastImageURL)
                            } else {
                                print("No valid image URL available")
                            }
                        }
                    }
                    completion(userProfile.id)
                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }
    
    
    private func loadProfileImageFromStorage(userID: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profilePicsRef = storageRef.child("profilePics/\(userID)/profileImage.jpg")
        
        profilePicsRef.getData(maxSize: 10 * 1024 * 1024) { [self] data, error in
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")

            } else {
                if let imageData = data, let loadedImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.userProfileImage = loadedImage
                    }
                }
            }
        }
    }
    
    
    private func checkProfileImageInStorage(userID: String, completion: @escaping (Bool) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profilePics/\(userID)/profileImage.jpg")
        
        profileImageRef.getMetadata { md, error in
            if let error = error {
                print("Could not find profile image file \(error.localizedDescription).")
                completion(false)
            } else if let _ = md {
                print("Found profile image")
                completion(true)
            }
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.userProfileImage = loadedImage
                    saveProfileImageToStorage(image: loadedImage, userID: self.userID)
                }
            } else {
                print("Failed to load image from URL:", error?.localizedDescription ?? "Unknown error")
            }
        }.resume()
    }
    
    private func saveProfileImageToStorage(image: UIImage, userID: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profilePicsRef = storageRef.child("profilePics/\(userID)/profileImage.jpg")
        
        // Upload image data to Firebase Storage
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        profilePicsRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading profile image to Firebase Storage: \(error.localizedDescription)")
                // Handle error
            } else {
                print("Profile image uploaded to Firebase Storage")
                // Handle success if needed
            }
        }
    }
    
}

//MARK: Playlist Cell Structs
struct PlaylistCellView: View {
    @StateObject private var imageLoader = ImageLoader()
    let playlist: Playlist
    let imageSize: CGFloat = 100
    
    var body: some View {
        Group {
            if let uiImage = imageLoader.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                    .cornerRadius(20)
                    .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 5)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                    .cornerRadius(20)
                    .onAppear {
                        imageLoader.loadImage(from: playlist.images.first?.url)
                    }
            }
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    func loadImage(from urlString: String?) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }.resume()
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}
