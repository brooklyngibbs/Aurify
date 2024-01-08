import SwiftUI
import Combine
import Firebase
import FirebaseStorage

struct LibraryView: View {
    @StateObject var viewModel = PlaylistListViewModel()
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
                                                    .frame(width: 80, height: 80)
                                                    .shadow(color: .white.opacity(1.0), radius: 7, x: 0, y: 0)
                                                
                                                Image(uiImage: userProfileImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 80, height: 80)
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
                            if viewModel.playlists.isEmpty {
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
                                    ForEach(viewModel.playlists.indices, id: \.self) { index in
                                        NavigationLink(destination: Playlist2VC(playlist: viewModel.playlists[index], userID: userID)) {
                                            PlaylistCellView(playlist: viewModel.playlists[index])
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
        .onAppear {
            fetchProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateLibraryView"))) { _ in
            print("arrived")
            fetchProfile()
        }
    }
    
    

    //MARK: PROFILE FUNCTIONS
    private func fetchProfile() {
        APICaller.shared.getCurrentUserProfile { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userProfile):
                    self.userID = userProfile.id
                    self.displayName = userProfile.display_name
                    
                    checkProfileImageInStorage(userID: self.userID) { profileImageExists in
                        if profileImageExists {
                            loadProfileImageFromStorage(userID: self.userID)
                        } else {
                            if let lastImageURLString = userProfile.images.last?.url,
                               let lastImageURL = URL(string: lastImageURLString) {
                                loadImage(from: lastImageURL)
                            } else {
                                print("No valid image URL available")
                            }
                        }
                    }
                    
                    viewModel.fetchDataFromFirestore(userID: self.userID) {
                        isLoading = false
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
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
        let profileImageRef = storageRef.child("profilePics/\(userID)")
        
        profileImageRef.listAll { result, error in
            if let error = error {
                print("Error listing files in Firebase Storage: \(error.localizedDescription)")
                completion(false)
            } else if let result = result {
                let profileImageExists = result.items.contains { $0.name == "profileImage.jpg" }
                completion(profileImageExists)
            } else {
                completion(false)
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

class PlaylistListViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    
    func fetchData(completion: @escaping () -> Void) {
        APICaller.shared.getCurrentUserPlaylists { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let playlists):
                    self?.playlists = playlists
                case .failure(let error):
                    print(error.localizedDescription)
                }
                completion()
            }
        }
    }
    
    func fetchDataFromFirestore(userID: String, completion: @escaping () -> Void) {
        // Fetch playlist URIs from FirestoreManager for the specific user ID
        FirestoreManager().fetchPlaylistIDs(forUserID: userID) { playlistIDs in
            // Introduce a delay to ensure the playlist URIs are received
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("Playlist ID found in Firestore:", playlistIDs) // Print the playlist URIs
                
                let dispatchGroup = DispatchGroup()
                for playlistID in playlistIDs {
                    dispatchGroup.enter()
                    APICaller.shared.getPlaylist(with: playlistID) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let playlist):
                                // Check if the fetched playlist already exists in the array
                                if !self.playlists.contains(where: { $0.id == playlist.id }) {
                                    // Insert the playlist at index 0 to add it at the beginning
                                    self.playlists.insert(playlist, at: 0)
                                }
                            case .failure(let error):
                                print("Failed to fetch playlist: \(error.localizedDescription)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion()
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
