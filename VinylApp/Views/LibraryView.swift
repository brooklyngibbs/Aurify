import SwiftUI
import Combine
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct LibraryView: View {
    @State private var playlists : [FirebasePlaylist] = []
    @State private var listener : ListenerRegistration?
    @State private var isLoading = true // Track loading state
    
    @State private var displayName: String = ""
    
    @State private var showingSettings = false
    @State private var userProfileImage: UIImage?
    @State private var showAllPlaylists = true
    
    var tabBarViewController: TabBarViewController
    
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
                        HStack {
                            CustomTitleView()
                                .padding(.top, 28.5)
                            
                            Spacer()
                            
                            Button(action: {
                                showingSettings = true
                            })
                            {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 25))
                                    .foregroundColor(Color(AppColors.vampireBlack))
                                    .padding(.trailing, 16)
                            }
                        }
                        .alignmentGuide(.top) { _ in 28.5 }
                        .popover(isPresented: $showingSettings) {
                            NavigationView {
                                SettingsViewController(userProfileImage: $userProfileImage, userName: self.displayName)
                                    .navigationBarTitleDisplayMode(.inline)
                                    .navigationBarItems(
                                        leading: EmptyView(),
                                        trailing: EmptyView()
                                    )
                                    .toolbar {
                                        ToolbarItem(placement: .principal) {
                                            HStack {
                                                Text("Settings")
                                                    .font(.custom("Outfit-Bold", size: 24))
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                        }
                                    }
                            }
                        }
                        
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
                                    }
                                }
                            }
                            .frame(height: 220)
                            .padding()
                            HStack {
                                Text("All")
                                    .font(.custom("Outfit-Bold", size: 18))
                                    .padding(.leading)
                                    .underline(showAllPlaylists == true, color: .black) // Underline if showAllPlaylists is false
                                    .onTapGesture {
                                        showAllPlaylists = true
                                    }
                                
                                Text("Favorites")
                                    .font(.custom("Outfit-Bold", size: 18))
                                    .padding(.leading)
                                    .underline(showAllPlaylists == false, color: .black) // Underline if showAllPlaylists is true
                                    .onTapGesture {
                                        showAllPlaylists = false
                                    }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            
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
                            } else if !showAllPlaylists {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(filteredPlaylists.indices, id: \.self) { index in
                                        NavigationLink(destination: Playlist2VC(playlist: filteredPlaylists[index], tabBarViewController: tabBarViewController)) {
                                            PlaylistCellView(playlist: filteredPlaylists[index])
                                                .padding(.bottom, 20)
                                                .id(UUID()) // Ensure each view has a unique ID
                                        }
                                        .id(filteredPlaylists[index].playlistId)
                                        
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(playlists.indices, id: \.self) { index in
                                        NavigationLink(destination: Playlist2VC(playlist: playlists[index], tabBarViewController: tabBarViewController)) {
                                            PlaylistCellView(playlist: playlists[index])
                                                .padding(.bottom, 20)
                                                .id(UUID()) // Ensure each view has a unique ID
                                        }
                                        .id(playlists[index].playlistId)
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
            let userID = Auth.auth().currentUser!.uid
            print("userID = \(userID)")
            listener?.remove()
            listener = FirestoreManager().fetchPlaylistIDListener(forUserID: userID) {
                playlists = $0
                isLoading = false
            }
            checkProfileImageInStorage(userID: userID) { profileImageExists in
                if profileImageExists {
                    loadProfileImageFromStorage(userID: userID)
                } else {
                    loadDefaultImageFromStorage()
                }
            }
            do {
                try await AuthManager.shared.retrieveClientToken()
            } catch {
                print("Error getting client token \(error.localizedDescription)")
            }
        }
        .onAppear {
            tabBarViewController.unhideUploadButton()
            fetchDisplayName()
        }
        .onDisappear() {
            listener?.remove()
            listener = nil
        }
    }
    
    //MARK: PROFILE FUNCTIONS
    
    private func fetchDisplayName() {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                if let displayName = document.data()?["name"] as? String {
                    self.displayName = displayName
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    private var filteredPlaylists: [FirebasePlaylist] {
        if showAllPlaylists {
            return playlists
        } else {
            return playlists.filter { $0.liked ?? false }
        }
    }
    
    
    //MARK: PROFILE FUNCTIONS
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
    
    private func loadDefaultImageFromStorage() {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profilePicsRef = storageRef.child("profilePics/defaultProfilePic.jpg")
        
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
    let playlist: FirebasePlaylist
    let imageSize: CGFloat = 110
    
    var body: some View {
        if let ciUrl = URL(string: playlist.coverImageUrl) {
            AsyncImage(url: ciUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                        .cornerRadius(20)
                        .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 5)
                case .failure:
                    if let val = playlist.images.first,
                       let eurl = URL(string: val) {
                        AsyncImage(url: eurl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                                    .cornerRadius(20)
                                    .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 5)
                            case .failure:
                                Color.gray.opacity(0.2)
                                    .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                                    .cornerRadius(20)
                            case .empty:
                                Color.gray.opacity(0.2)
                                    .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                                    .cornerRadius(20)
                            @unknown default:
                                Color.gray.opacity(0.2)
                                    .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                                    .cornerRadius(20)
                            }
                        }
                    }
                case .empty:
                    Color.gray.opacity(0.2)
                        .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                        .cornerRadius(20)
                @unknown default:
                    Color.gray.opacity(0.2)
                        .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                        .cornerRadius(20)
                }
            }
        } else if let estr = playlist.images.first,
                  let eurl = URL(string: estr) {
            AsyncImage(url: eurl) { phase in
                switch(phase) {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                        .cornerRadius(20)
                        .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 5)
                case .failure:
                    Color.gray.opacity(0.2)
                        .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                        .cornerRadius(20)
                case .empty:
                    Color.gray.opacity(0.2)
                        .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                        .cornerRadius(20)
                @unknown default:
                    Color.gray.opacity(0.2)
                        .frame(width: imageSize, height: imageSize) // Set width and height to create a square
                        .cornerRadius(20)
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
