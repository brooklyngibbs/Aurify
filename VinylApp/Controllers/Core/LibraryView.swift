import SwiftUI
import Combine

struct LibraryView: View {
    @StateObject var viewModel = PlaylistListViewModel()
    @State private var isLoading = true // Track loading state
    @State private var userProfileImage: UIImage?
    @State private var displayName: String = ""
    
    var body: some View {
        ZStack {
            if isLoading {
                // loading circle
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .foregroundColor(Color(AppColors.vampireBlack))
            } else {
                NavigationView {
                    if viewModel.playlists.isEmpty {
                        Text("You Don't Have Any Playlists Yet")
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            CustomTitleView()
                            
                            ScrollView {
                                ZStack {
                                    Rectangle()
                                        .foregroundColor(Color(AppColors.moonstoneBlue))
                                        .cornerRadius(20)
                                        .padding(.bottom, 25)
                                    
                                    if let userProfileImage = userProfileImage {
                                        GeometryReader { geometry in
                                            VStack(spacing: 10) {
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
                                                    .font(.custom("Outfit-Bold", size: 14))
                                                
                                                Spacer()
                                            }
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .padding(.top, (geometry.size.height - 140) / 2)
                                            .padding(.horizontal, 20) // Add horizontal padding
                                        }
                                    }
                                }
                                .frame(height: 200)
                                .padding()
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(viewModel.playlists) { playlist in
                                        NavigationLink(destination: Playlist2VC(playlist: playlist)) {
                                            PlaylistCellView(playlist: playlist)
                                                .padding(.bottom, 20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarTitle("", displayMode: .inline)
                .accentColor(Color(AppColors.vampireBlack))
            }
        }
        .onAppear {
            viewModel.fetchData {
                isLoading = false
                fetchProfile()
            }
        }
    }
    
    private func fetchProfile() {
        APICaller.shared.getCurrentUserProfile { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userProfile):
                    if let imageURL = userProfile.images.first?.url,
                       let firstImageURL = URL(string: imageURL) {
                        if userProfile.images.count > 1 {
                            // If there are more than one image, try to use the second image URL
                            if let secondImageURL = URL(string: userProfile.images[1].url) {
                                self.loadImage(from: secondImageURL)
                            } else {
                                self.loadImage(from: firstImageURL)
                            }
                        } else {
                            self.loadImage(from: firstImageURL)
                        }
                    } else {
                        print("No image URL available")
                    }
                    self.displayName = userProfile.display_name
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    // Set the loaded image to your UIImage property
                    self.userProfileImage = loadedImage
                }
            } else {
                print("Failed to load image from URL:", error?.localizedDescription ?? "Unknown error")
            }
        }.resume()
    }
    
}

struct PlaylistCellView: View {
    @StateObject private var imageLoader = ImageLoader()
    let playlist: Playlist
    let imageHeight: CGFloat = 100 // Set the desired image height
    
    var body: some View {
        Group {
            if let uiImage = imageLoader.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: imageHeight)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 5)
            } else {
                Color.gray.opacity(0.2)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: imageHeight)
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
