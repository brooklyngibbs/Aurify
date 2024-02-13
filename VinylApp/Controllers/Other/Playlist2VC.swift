import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

struct Playlist2VC: View {
    let playlist: FirebasePlaylist
    @State private var viewModels = [RecommendedTrackCellViewModel]()
    private var cancellables = Set<AnyCancellable>()
    @State private var imageHeight: CGFloat = UIScreen.main.bounds.width
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var updateLibraryView: (() -> Void)?
    @AppStorage("user_id") private var spotifyId: String = ""
    @State private var showingAuthView = false
    @State private var showAlert = false
    @State private var uploadingPlaylist = false
    
    var tabBarViewController: TabBarViewController
    
    private let db = Firestore.firestore()
    
    internal init(playlist: FirebasePlaylist, tabBarViewController: TabBarViewController) {
        self.playlist = playlist
        self.tabBarViewController = tabBarViewController
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
            Text(formatPlaylistName(playlist.name))
                .padding(.top, 20)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: .leading)
                .lineLimit(4)
                .font(.custom("Outfit-Bold", size: 25))
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                openInSpotifyButton
            Spacer()
        }
    }
    
    private func formatPlaylistName(_ name: String) -> String {
        // Replace ":" with "\n"
        return name.replacingOccurrences(of: ": ", with: ":\n")
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
        var spotifyId = playlist.spotifyId
        if spotifyId == "" {
            defer {
                uploadingPlaylist = false
            }
            uploadingPlaylist = true
            // create playlist in spotify
            let imageManager = try await ImageManager(URL(string: playlist.coverImageUrl)!)
            let base64Data = try imageManager.convertImageToBase64(maxBytes: 256_000)
            print("Creating playlist")
            let spotifyPlaylist = try await APICaller.shared.createPlaylist(with: playlist.name, description: "Created by Aurify")
            spotifyId = spotifyPlaylist.id
            print("Updating playlist image")
            try await APICaller.shared.updatePlaylistImage(imageBase64: base64Data, playlistId: spotifyPlaylist.id)
            let _ = try await APICaller.shared.addTrackArrayToPlaylist(trackURI: playlist.playlistDetails.map {$0.spotifyUri}, playlistId: spotifyPlaylist.id)
            let updatedPlaylist = try await APICaller.shared.getPlaylist(with: spotifyId)
            // update firestore
            try await FirestoreManager().updateFirestoreWithSpotify(userId: Auth.auth().currentUser!.uid, fsPlaylist: playlist, spPlaylist: updatedPlaylist)
        }
        guard let spotifyURL = URL(string: "spotify:playlist:\(spotifyId)"),
              await UIApplication.shared.canOpenURL(spotifyURL) else {
            // If the Spotify app is not installed, open the App Store link
            guard let appStoreURL = URL(string: "https://apps.apple.com/us/app/spotify-music/id324684580") else {
                return
            }
            await UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            return
        }

        // If the Spotify app is installed, open the playlist in the app
        await UIApplication.shared.open(spotifyURL, options: [:], completionHandler: nil)
    }
    
    private var trackList: some View {
        ForEach(playlist.playlistDetails, id: \.spotifyUri) { details in
            let isLastCell = details.spotifyUri == playlist.playlistDetails.last?.spotifyUri
            TrackCell(viewModel: RecommendedTrackCellViewModel(name: details.title, artistName: details.artistName, artworkURL: URL(string: details.artworkUrl)), isLastCell: isLastCell)
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
        guard let spotifyURL = spotifyURL else {
            return
        }

        let customShareMessage = "Check out my Aurify!"

        let activityViewController = UIActivityViewController(
            activityItems: [customShareMessage, spotifyURL],
            applicationActivities: nil
        )

        if UIDevice.current.userInterfaceIdiom == .pad {
            // On iPad, set the popover properties to nil if not presenting from a specific view
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

    private func deletePlaylist() {
        if let userId = Auth.auth().currentUser?.uid {
            print("User ID: \(userId)")
            print("Playlist ID: \(playlist.playlistId)")
            // Delete the playlist cover image
            db.collection("users").document(userId).collection("playlists").document(playlist.playlistId).setData(["deleted": true], merge: true)
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
    
    var body: some View {
        HStack(spacing: 10) {
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
        }
        .padding(.leading, 20)
        .cornerRadius(12)
        
    }
}


