import SwiftUI
import Combine
import FirebaseFirestore

struct Playlist2VC: View {
    let playlist: Playlist
    let userID: String
    @State private var viewModels = [RecommendedTrackCellViewModel]()
    private var cancellables = Set<AnyCancellable>()
    @State private var imageHeight: CGFloat = UIScreen.main.bounds.width
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var updateLibraryView: (() -> Void)?
    
    private let db = Firestore.firestore()
    
    internal init(playlist: Playlist, userID: String) {
        self.playlist = playlist
        self.userID = userID 
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.edgesIgnoringSafeArea(.all)
            if let imageURL = playlist.images.first?.url, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                    case .failure:
                        Text("Failed to load image")
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
                .padding(.top, 4 * 320 / 5) // tracks starting position (4/5 of image)
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
            fetchPlaylistDetails()
        }
        .onDisappear {
            NotificationCenter.default.post(name: NSNotification.Name("UpdateLibraryView"), object: nil)
        }
    }
    
    private var playlistHeader: some View {
        VStack {
            Text(playlist.name)
                .padding(.top, 20)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                .lineLimit(4)
                .font(.custom("Outfit-Bold", size: 25))
                .foregroundColor(.black)
                .padding()
                .background(Color.white)

            openInSpotifyButton
            Spacer()
        }
    }
    
    private var openInSpotifyButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 200, height: 40)
                .foregroundColor(Color(AppColors.moonstoneBlue))

            Button(action: {
                openSpotify()
            }) {
                HStack {
                    Image("Spotify_Icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    
                    Text("OPEN SPOTIFY")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                .offset(x: 10) // Adjust the offset as needed to center the HStack
            }
            .padding(.trailing, 20)
        }
    }
    
    private func openSpotify() {
        guard let spotifyURL = URL(string: "spotify:playlist:\(playlist.id)"),
              UIApplication.shared.canOpenURL(spotifyURL) else {
            // If the Spotify app is not installed, open the App Store link
            guard let appStoreURL = URL(string: "https://apps.apple.com/us/app/spotify-music/id324684580") else {
                return
            }
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            return
        }

        // If the Spotify app is installed, open the playlist in the app
        UIApplication.shared.open(spotifyURL, options: [:], completionHandler: nil)
    }
    
    private var trackList: some View {
        ForEach(viewModels.indices, id: \.self) { index in
            let isLastCell = index == viewModels.indices.last
            TrackCell(viewModel: viewModels[index], isLastCell: isLastCell)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(viewModels[index].isTrackTapped ? Color.gray.opacity(0.3) : Color.white)
                )
                .padding(.bottom, isLastCell ? 20 : 0)
        }
        .padding(.top, 20)
    }
    
    private var spotifyURL: URL? {
        if let spotifyURLString = playlist.external_urls!["spotify"] as? String {
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

        UIApplication.shared.windows.first?.rootViewController?.present(
            activityViewController,
            animated: true,
            completion: nil
        )
    }

    
    private func deletePlaylist() {
        if let userSpotifyID = UserDefaults.standard.value(forKey: "user_id") as? String {
            print("User ID: \(userSpotifyID)")
            print("Playlist ID: \(playlist.id)")
            
            let userPlaylistsRef = db.collection("users").document(userSpotifyID).collection("playlists")
            userPlaylistsRef.document(playlist.id).delete { error in
                if let error = error {
                    print("Error deleting document: \(error)")
                } else {
                    print("Playlist successfully deleted")
                    DispatchQueue.main.async {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } else {
            print("No user ID found in UserDefaults or it's not a String")
        }
    }
    
    private func fetchPlaylistDetails() {
        APICaller.shared.getPlaylistDetails(for: playlist) { result in
            switch result {
            case .success(let model):
                DispatchQueue.main.async {
                    self.viewModels = model.tracks.items.compactMap({
                        RecommendedTrackCellViewModel(
                            name: $0.track.name,
                            artistName: $0.track.artists.first?.name ?? "-",
                            artworkURL: URL(string: $0.track.album?.images.first?.url ?? "")
                        )
                    })
                }
            case .failure(let error):
                print("API Error: \(error.localizedDescription)")
            }
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


