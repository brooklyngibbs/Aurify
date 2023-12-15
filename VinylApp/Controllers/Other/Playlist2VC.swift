import SwiftUI
import Combine

struct Playlist2VC: View {
    let playlist: Playlist
    @State private var viewModels = [RecommendedTrackCellViewModel]()
    private var cancellables = Set<AnyCancellable>()
    @State private var imageHeight: CGFloat = UIScreen.main.bounds.width
    
    internal init(playlist: Playlist) {
        self.playlist = playlist
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(AppColors.gainsboro).edgesIgnoringSafeArea(.all)
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
        .onAppear {
            fetchPlaylistDetails()
        }
    }
    
    private var playlistHeader: some View {
            HStack {
                Text(playlist.name)
                    .padding(.top, 20)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.6, alignment: .leading)
                    .lineLimit(4)
                    .font(.custom("Outfit-Bold", size: 25))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                VStack {
                    openInSpotifyButton
                }
                postButton
            }
    }

    
    private var postButton: some View {
        Button(action: {
            // Handle posting action
            // Navigate to PostView or perform post-related actions here
        }) {
            Text("Post")
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Color(AppColors.moonstoneBlue))
                .cornerRadius(8)
                .font(.custom("Inter-Medium", size: 16))
        }
        .padding(.horizontal, 20)
    }
    
    private var openInSpotifyButton: some View {
        Button(action: {
            openSpotify()
        }) {
            Image("Spotify_Icon") // Replace "spotify_icon" with your image name
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50) // Adjust size as needed
                .background(Color.white)
                .cornerRadius(8)
        }
        .padding(.trailing, 10)
    }

    // Function to open Spotify with the playlist
    private func openSpotify() {
        let spotifyURL = URL(string: "spotify:playlist:\(playlist.id)")!
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
                .onTapGesture {
                    viewModels.indices.forEach { viewModels[$0].isTrackTapped = false }
                    viewModels[index].isTrackTapped.toggle()
                    APICaller.shared.startPlaybackRequestByTrack(with: "spotify:playlist:\(playlist.id)", offset: index)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                        viewModels[index].isTrackTapped = false
                    }
                }
                .padding(.bottom, isLastCell ? 20 : 0)
        }
        .padding(.top, 20)
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
