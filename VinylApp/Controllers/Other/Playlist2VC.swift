import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
import Firebase
import FirebaseAnalytics
import AVKit

class PlayerViewModel: ObservableObject {
    @Published var currentlyPlayingTrack: AVPlayer?
    @Published var currentlyPlayingTrackId: String?
}

struct Playlist2VC: View {
    var playlist: FirebasePlaylist
    @State private var viewModels = [RecommendedTrackCellViewModel]()
    private var cancellables = Set<AnyCancellable>()
    @State private var spotifyPlaylistId = ""
    @State private var imageHeight: CGFloat = UIScreen.main.bounds.width
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var updateLibraryView: (() -> Void)?
    @AppStorage("user_id") private var spotifyId: String = ""
    @State private var showingAuthView = false
    @State private var showAlert = false
    @State private var uploadingPlaylist = false
    @State private var liked: Bool?
    @State private var currentlyPlayingTrack: AVPlayer?
    @StateObject var playerViewModel = PlayerViewModel()
    
    var tabBarViewController: TabBarViewController
    
    private let db = Firestore.firestore()
    
    internal init(playlist: FirebasePlaylist, tabBarViewController: TabBarViewController) {
        self.playlist = playlist
        self.tabBarViewController = tabBarViewController
        self.spotifyPlaylistId = playlist.spotifyId
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.edgesIgnoringSafeArea(.all)
            if let url = URL(string: playlist.coverImageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                    case .failure:
                        if let spotifyImageUrlString = playlist.images.first,
                           let spotifyImageUrl = URL(string: spotifyImageUrlString) {
                            AsyncImage(url: spotifyImageUrl) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                                case .failure:
                                    Text("Failed to load backup image")
                                case .empty:
                                    Text("Loading image")
                                @unknown default:
                                    Text("Loading image")
                                }
                            }
                        } else {
                            Text("Failed to load image")
                        }
                    case .empty:
                        Text("Loading image")
                    @unknown default:
                        Text("Loading image")
                    }
                }
            } else {
                Text("No image available")
                    .frame(height: 320)
            }
            ScrollView {
                VStack(spacing: 0) {
                    playlistHeader
                    Spacer()
                    trackList
                }
                .frame(maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(color: Color(AppColors.vampireBlack).opacity(0.4), radius: 10, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.top, 4 * 320 / 5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(0)
            GeometryReader { geometry in
                let screenHeight = geometry.size.height
                let blurHeight = screenHeight / 5
                
                // Create a gradient to fade out the blur effect
                let gradient = LinearGradient(gradient: Gradient(colors: [.clear, .white]), startPoint: .top, endPoint: .bottom)
                
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(gradient)
                        .frame(height: blurHeight)
                        .blur(radius: 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .padding(0)
        .navigationBarHidden(false)
        .toolbarRole(.editor)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        sharePlaylist()
                    }) {
                        Label("Share Playlist", systemImage: "square.and.arrow.up")
                    }
                    Button(action: {
                        deletePlaylist()
                    }) {
                        Label("Delete Playlist", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.black)
                        .imageScale(.large)
                }
            }
        }
        .onAppear {
            tabBarViewController.hideUploadButton()
        }
        .onDisappear {
            NotificationCenter.default.post(name: NSNotification.Name("UpdateLibraryView"), object: nil)
            tabBarViewController.unhideUploadButton()
        }
        .sheet(isPresented: $showingAuthView) {
            AuthViewControllerWrapper(isPresented: $showingAuthView, loginCompletion: { success in
                if success {
                    // Once authentication succeeds, get the user profile
                    APICaller.shared.getCurrentUserProfile { result in
                        switch result {
                        case .success(let userProfile):
                            // Set the user_id here
                            print("Setting user default \(userProfile.id)")
                            UserDefaults.standard.set(userProfile.id, forKey: "user_id")
                            // Handle further navigation or actions
                        case .failure(let error):
                            // Handle the failure to get the user profile
                            print("Error fetching user profile: \(error)")
                            showAlert = true
                        }
                    }
                } else {
                    // Handle login failure
                    showAlert = true
                }
                showingAuthView = false
                if !showAlert {
                    Task {
                        do {
                            try await createPlaylist()
                        } catch {
                            print("Error creating playlist: \(error.localizedDescription)")
                        }
                    }
                }
            })
        }.overlay( content: {
            if uploadingPlaylist {
                ZStack {
                    Color(white: 0.2, opacity: 0.4)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(4)
                        .tint(.white)
                }.transition(.move(edge: .bottom))
            }
        })
    }
    
    private var playlistHeader: some View {
        VStack {
            HStack {
                Text(formatPlaylistName(playlist.name))
                    .padding(.top, 20)
                    .frame(maxWidth: UIScreen.main.bounds.width, alignment: .leading)
                    .lineLimit(4)
                    .font(.custom("Outfit-Bold", size: 25))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                Spacer()
                likeButton()
                Spacer()
            }
            openInSpotifyButton
            Spacer()
        }
    }
    
    private func formatPlaylistName(_ name: String) -> String {
        // Replace ":" with "\n"
        return name.replacingOccurrences(of: ": ", with: ":\n")
    }
    
    // MARK: Like Button
    private func likeButton() -> some View {
        Button(action: {
            likePlaylist {
                // Empty closure as the completion parameter
            }
        }) {
            ZStack {
                Image(systemName: "heart.fill")
                    .opacity(liked ?? false ? 1 : 0)
                    .scaleEffect(liked ?? false ? 1.0 : 0.1)
                    .foregroundColor(liked ?? false ? Color(AppColors.liked_color) : .black)
                    .animation(Animation.linear(duration: 0.3), value: liked)
                Image(systemName: "heart")
                    .foregroundColor(liked ?? false ? Color(AppColors.liked_color) : .black)
            }
            .font(.system(size: 35))
            .padding()
            .padding(.top, 20)
        }
        .onAppear {
            fetchLikedStatus()
        }
    }
    
    
    private func fetchLikedStatus() {
        FirestoreManager().fetchLikedStatus(forUserID: Auth.auth().currentUser?.uid ?? "", playlistID: playlist.playlistId) { liked, error in
            if let error = error {
                print("Error fetching liked status: \(error.localizedDescription)")
            } else {
                // Update the liked state
                self.liked = liked ?? false
            }
        }
    }
    
    private func likePlaylist(completion: @escaping () -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated.")
            return
        }
        
        let userPlaylistRef = db.collection("users").document(userId).collection("playlists").document(playlist.playlistId)
        
        // If liked is nil, default to false
        let newLikedValue = !(liked ?? false)
        
        userPlaylistRef.setData(["liked": newLikedValue], merge: true) { error in
            if let error = error {
                print("Error updating liked status: \(error)")
            } else {
                print("Liked status updated successfully.")
                print("New liked value: \(newLikedValue)")
                // Update liked state
                self.liked = newLikedValue
                // Update playlist property in the enclosing view
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    private var openInSpotifyButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 200, height: 40)
                .foregroundColor(Color(AppColors.moonstoneBlue))
            
            Button(action: {
                Task {
                    try await openSpotify()
                }
            }) {
                HStack {
                    Image("Spotify_Icon_White")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    
                    Text("OPEN SPOTIFY")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .offset(x: 10)
            }
            .padding(.trailing, 20)
            .disabled(uploadingPlaylist)
        }
    }
    
    private func openSpotify() async throws {
        // ensure user is logged into spotify
        if spotifyId == "" {
            // log into spotify
            showingAuthView = true
            return
        }
        try await createPlaylist()
    }
    
    private func createPlaylist() async throws {
        // ensure playlist exists in spotify
        if spotifyPlaylistId == "" {
            spotifyPlaylistId = try await FirestoreManager().fetchPlaylistIdForDocument(forUserID: Auth.auth().currentUser!.uid, firestorePlaylistId: playlist.playlistId) ?? ""
        }
        if spotifyPlaylistId == "" {
            defer {
                uploadingPlaylist = false
            }
            uploadingPlaylist = true
            // create playlist in spotify
            let imageManager = try await ImageManager(URL(string: playlist.coverImageUrl)!)
            let base64Data = try imageManager.convertImageToBase64(maxBytes: 256_000)
            print("Creating playlist")
            let spotifyPlaylist = try await APICaller.shared.createPlaylist(with: playlist.name, description: "Created by Aurify")
            spotifyPlaylistId = spotifyPlaylist.id
            print("Updating playlist image")
            try await APICaller.shared.updatePlaylistImage(imageBase64: base64Data, playlistId: spotifyPlaylist.id)
            let _ = try await APICaller.shared.addTrackArrayToPlaylist(trackURI: playlist.playlistDetails.map {$0.spotifyUri}, playlistId: spotifyPlaylist.id)
            let updatedPlaylist = try await APICaller.shared.getPlaylist(with: spotifyPlaylistId)
            // update firestore
            try await FirestoreManager().updateFirestoreWithSpotify(userId: Auth.auth().currentUser!.uid, fsPlaylist: playlist, spPlaylist: updatedPlaylist)
        }
        guard let spotifyURL = URL(string: "spotify:playlist:\(spotifyPlaylistId)"),
              await UIApplication.shared.canOpenURL(spotifyURL) else {
            // If the Spotify app is not installed, open the App Store link
            guard let appStoreURL = URL(string: "https://apps.apple.com/us/app/spotify-music/id324684580") else {
                return
            }
            Analytics.logEvent("directed_to_app_store", parameters: nil)
            await UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            return
        }
        
        // If the Spotify app is installed, open the playlist in the app
        Analytics.logEvent("build_playlist_spotify", parameters: nil)
        await UIApplication.shared.open(spotifyURL, options: [:], completionHandler: nil)
    }
    
    private func createPlaylistAndReturnURL() async throws -> URL? {
        // Ensure playlist exists in Spotify
        if spotifyPlaylistId == "" {
            spotifyPlaylistId = try await FirestoreManager().fetchPlaylistIdForDocument(forUserID: Auth.auth().currentUser!.uid, firestorePlaylistId: playlist.playlistId) ?? ""
        }
        
        if spotifyPlaylistId == "" {
            defer {
                uploadingPlaylist = false
            }
            
            uploadingPlaylist = true
            
            // Create playlist in Spotify
            let imageManager = try await ImageManager(URL(string: playlist.coverImageUrl)!)
            let base64Data = try imageManager.convertImageToBase64(maxBytes: 256_000)
            
            print("Creating playlist")
            let spotifyPlaylist = try await APICaller.shared.createPlaylist(with: playlist.name, description: "Created by Aurify")
            spotifyPlaylistId = spotifyPlaylist.id
            
            print("Updating playlist image")
            try await APICaller.shared.updatePlaylistImage(imageBase64: base64Data, playlistId: spotifyPlaylist.id)
            
            let _ = try await APICaller.shared.addTrackArrayToPlaylist(trackURI: playlist.playlistDetails.map {$0.spotifyUri}, playlistId: spotifyPlaylist.id)
            
            let updatedPlaylist = try await APICaller.shared.getPlaylist(with: spotifyPlaylistId)
            
            // Update Firestore
            try await FirestoreManager().updateFirestoreWithSpotify(userId: Auth.auth().currentUser!.uid, fsPlaylist: playlist, spPlaylist: updatedPlaylist)
        }
        
        // Print Spotify playlist ID for debugging
        print("Spotify playlist ID: \(spotifyPlaylistId)")
        
        let updatedPlaylist = try await APICaller.shared.getPlaylist(with: spotifyPlaylistId)
        
        // Return the Spotify playlist URL
        let spotifyURL = updatedPlaylist.externalUrls!["spotify"]
        return URL(string: spotifyURL ?? "")
    }
    
    
    
    private var trackList: some View {
        ForEach(playlist.playlistDetails, id: \.spotifyUri) { details in
            let isLastCell = details.spotifyUri == playlist.playlistDetails.last?.spotifyUri
            TrackCell(viewModel: RecommendedTrackCellViewModel(name: details.title, artistName: details.artistName, artworkURL: URL(string: details.artworkUrl), previewUrl: details.previewUrl), isLastCell: isLastCell, playerViewModel: playerViewModel, trackId: details.spotifyUri)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(Color.white)
                )
                .padding(.bottom, isLastCell ? 20 : 0)
        }
        .padding(.top, 20)
    }
    
    private var spotifyURL: URL? {
        if let spotifyURLString = playlist.externalUrls["spotify"] {
            return URL(string: spotifyURLString)
        }
        return nil
    }
    
    private func sharePlaylist() {
        Analytics.logEvent("share_playlist", parameters: nil)
        
        if let spotifyURL = spotifyURL {
            share(items: ["Check out my Aurify!", spotifyURL])
        } else {
            Task {
                do {
                    if let playlistURL = try await createPlaylistAndReturnURL() {
                        share(items: ["Check out my Aurify!", playlistURL])
                    } else {
                        print("Unable to share playlist. Spotify playlist URL is empty.")
                    }
                } catch {
                    print("Error creating playlist: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func share(items: [Any]) {
        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = nil
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 0, height: 0)
                activityViewController.popoverPresentationController?.permittedArrowDirections = []
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(
                    activityViewController,
                    animated: true,
                    completion: nil
                )
            }
        }
    }
    
    private func deletePlaylist() {
        if let userId = Auth.auth().currentUser?.uid {
            print("User ID: \(userId)")
            print("Playlist ID: \(playlist.playlistId)")
            // Delete the playlist cover image
            db.collection("users").document(userId).collection("playlists").document(playlist.playlistId).setData(["deleted": true], merge: true)
            Analytics.logEvent("delete_playlist", parameters: nil)
            DispatchQueue.main.async {
                self.presentationMode.wrappedValue.dismiss()
            }
        } else {
            print("No user ID found in UserDefaults or it's not a String")
        }
    }
    
    private func didTapShare() {
        // Handle share action here
    }
}

struct TrackCell: View {
    let viewModel: RecommendedTrackCellViewModel
    let isLastCell: Bool
    @State private var isPlaying = false
    @State private var isClicked = false
    @ObservedObject var playerViewModel: PlayerViewModel
    let trackId: String

    var body: some View {
        HStack(spacing: 10) {
            // Track artwork and details
            if let artworkURL = viewModel.artworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 45, height: 45)
                    default:
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 45, height: 45)
                    }
                }
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 45)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.name)
                    .font(.custom("Inter-Medium", size: 15))
                    .lineLimit(1)
                Text(viewModel.artistName)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isPlaying {
                Button(action: {
                    playerViewModel.currentlyPlayingTrack?.pause()
                    playerViewModel.currentlyPlayingTrack = nil
                    playerViewModel.currentlyPlayingTrackId = nil
                    isPlaying = false
                }) {
                    Image(systemName: "pause.circle")
                        .font(.system(size: 25))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20) // Apply padding to the Image instead of the Button
                }
                .buttonStyle(PlainButtonStyle()) // Add this line to remove any default button styling
            }
        }
        .padding(.leading, 20)
        .cornerRadius(12)
        .onDisappear {
            playerViewModel.currentlyPlayingTrack?.pause()
        }
        .background(isClicked ? Color.gray.opacity(0.2) : Color.clear)
        .onTapGesture {
            guard let url = URL(string: viewModel.previewUrl) else {
                print("Preview URL is not valid")
                return
            }

            if isPlaying {
                playerViewModel.currentlyPlayingTrack?.pause()
                playerViewModel.currentlyPlayingTrack = nil
                playerViewModel.currentlyPlayingTrackId = nil
                isPlaying = false
            } else {
                if playerViewModel.currentlyPlayingTrackId != trackId {
                    playerViewModel.currentlyPlayingTrack?.pause()
                    playerViewModel.currentlyPlayingTrackId = nil
                }

                let playerItem = AVPlayerItem(url: url)
                let newPlayer = AVPlayer(playerItem: playerItem)
                newPlayer.play()

                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
                    self.isPlaying = false
                    self.playerViewModel.currentlyPlayingTrack = nil
                    self.playerViewModel.currentlyPlayingTrackId = nil
                }

                playerViewModel.currentlyPlayingTrack = newPlayer
                playerViewModel.currentlyPlayingTrackId = trackId
                isPlaying = true
            }

            isClicked.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isClicked.toggle()
            }
        }
        .onChange(of: playerViewModel.currentlyPlayingTrackId) { newTrackId in
            if newTrackId != trackId {
                isPlaying = false
            }
        }
    }
}
