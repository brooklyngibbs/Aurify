//
//  Upload2VC.swift
//  VinylApp
//
//  Created by Tanton Gibbs on 1/20/24.
//

import SwiftUI

struct UploadErrorView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Spacer()
        Text("Uh Oh!\nSomething went wrong.")
            .foregroundStyle(Color(AppColors.vampireBlack))
            .font(.custom("Inter-SemiBold", size: 17))
            .multilineTextAlignment(.center)
        Image("error")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
        Button(action: {
            dismiss()
        }) {
            Text("Back to Library")
                .foregroundColor(Color(AppColors.vampireBlack))
                .font(.custom("Inter-SemiBold", size: 17))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(AppColors.vampireBlack), lineWidth: 1)
                )
                .background(Color.white)
        }
        Spacer()
    }
}

class APIRunner {
    private var dataTask: URLSessionDataTask? = nil
    private let imageAPIURL = URL(string: "https://make-scene-api-request-36d3pxwmrq-uc.a.run.app")!
    private let topArtists: [String] = []
    
    private func createAPIRequest(imageUrl: String) throws -> URLRequest {
        var request = URLRequest(url: imageAPIURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        
        let requestData = [
            "image_url": imageUrl,
            "artists": topArtists
        ] as [String : Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestData)
        request.httpBody = jsonData
        return request
    }
    
    private func createPlaylist(title: String, desc: String) async throws -> Playlist {
        return try await withCheckedThrowingContinuation() { continuation in
            APICaller.shared.createPlaylist(with: title, description: desc) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func updatePlaylistImage(base64String: String, playlistID: String) async throws {
        try await withCheckedThrowingContinuation() { continuation in
            APICaller.shared.updatePlaylistImageWithRetries(imageBase64: base64String, playlistID: playlistID, retries: 2) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func addTracksToPlaylist(playlistID: String, songURIs: [String]) async throws {
        // Here you have collected all song URIs in self.songURIs
        // You can now add these tracks to the playlist using the obtained URIs
        let _ = try await withCheckedThrowingContinuation() { continuation in
            let startTime = DispatchTime.now()
            APICaller.shared.addTrackArrayToPlaylist(trackURI: songURIs, playlist_id: playlistID) { addResult in
                print("addTrackArrayToPlaylist time: \(Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000)")
                continuation.resume(with: addResult)
            }
        }
    }
    
    private func searchAndAppendTrackURIs(songs: [SongInfo], playlistID: String) async throws {
        let songURIs = await withCheckedContinuation() { continuation in
            let startTime = DispatchTime.now()
            APICaller.shared.searchManySongs(q: songs) {results in
                print("searchManySongs time: \(Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000)")
                let songURIs = results.compactMap {result in
                    switch(result) {
                    case .success(let trackURI):
                        return trackURI
                    case .failure(_):
                        return nil
                    }
                }
                continuation.resume(returning: songURIs)
            }
        }
        try await addTracksToPlaylist(playlistID: playlistID, songURIs: songURIs)
    }
    
    private func savePlaylistToFirestore(userID: String, playlist: Playlist, imageUrl: String, imageInfo: ImageInfo) async throws {
        try await withCheckedThrowingContinuation() { continuation in
            FirestoreManager().savePlaylistToFirestore(userID: userID, playlist: playlist, imageUrl: imageUrl, imageInfo: imageInfo) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func getCurrentUserProfile() async throws -> UserProfile {
        return try await withCheckedThrowingContinuation() { continuation in
            APICaller.shared.getCurrentUserProfile { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func getPlaylist(playlistId: String) async throws -> Playlist {
        return try await withCheckedThrowingContinuation() { continuation in
            APICaller.shared.getPlaylist(with: playlistId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func retry<T>(times: Int, fn: () async throws -> (T)) async throws -> T {
        do {
            return try await fn()
        } catch {
            if times > 0 {
                return try await retry(times: times - 1, fn: fn)
            } else {
                throw error
            }
        }
    }
    
    func run(image: UIImage) -> Task<Playlist, Error> {
        let task = Task {
            let imageManager = ImageManager(image)
            print("Uploading to storage")
            let url = try await imageManager.uploadImageToStorage()
            print("Creating api request")
            let json = try await retry(times: 2) {
                let request = try createAPIRequest(imageUrl: url)
                let (data, _) = try await URLSession.shared.data(for: request)
                print("Data = \(String(data: data, encoding: .utf8) ?? "")")
                print("Decoding JSON")
                return try JSONDecoder().decode(ImageInfo.self, from: data)
            }
            print("Converting image")
            let base64Data = try imageManager.convertImageToBase64(maxBytes: 256_000)
            print("Creating playlist")
            let playlist = try await createPlaylist(title: json.playlistTitle, desc: json.description)
            print("Updating playlist image")
            try await updatePlaylistImage(base64String: base64Data, playlistID: playlist.id)
            print("Adding Tracks")
            try await searchAndAppendTrackURIs(songs: json.songlist, playlistID: playlist.id)
            let userId = try await getCurrentUserProfile().id
            print("Saving playlist to firestore")
            try await savePlaylistToFirestore(userID: userId, playlist: playlist, imageUrl: url, imageInfo: json)
            // Refetch playlist to get updated image urls
            return try await getPlaylist(playlistId: playlist.id)
        }
        return task
    }
}

struct SpinningVinylView: View {
    @State private var degreesRotating = 0.0
    @State private var generatingText = "Generating your picture playlist. Do not exit out of app"
    @State private var labelTimer : Timer?
    private var topArtists: [String] = []
    
    private var foreverAnimation : Animation {
        Animation.linear(duration: 1.0)
            .repeatForever(autoreverses: false)
    }
    
    private func startLabelTimer() {
        labelTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [self] _ in
            generatingText = LabelTexts.labelTexts.randomElement() ?? ""
        }
    }
    
    private func stopLabelTimer() {
        labelTimer?.invalidate()
        labelTimer = nil
    }
    
    var body: some View {
        VStack {
            Spacer()
            Image("vinyl3")
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(degreesRotating))
                .onAppear {
                    withAnimation(foreverAnimation) {
                        degreesRotating = 360.0
                    }
                }
                .onDisappear() {
                    degreesRotating = 0.0
                }
                .frame(width: 200, height: 200)
                .padding(20)
            Text(generatingText)
                .foregroundStyle(Color(AppColors.vampireBlack))
                .font(.custom("Inter-Light", size: 17))
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
                .onAppear() {
                    startLabelTimer()
                }
                .onDisappear() {
                    stopLabelTimer()
                }
            Spacer()
        }
    }
}

struct PleaseSubscribeView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Spacer()
            Text("Subscribe to get more of Aurify!")
                .lineLimit(3, reservesSpace: true)
                .multilineTextAlignment(.center)
                .font(.custom("Inter-SemiBold", size: 17))
            Image("headphones")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            Button(action: {
                dismiss()
            }) {
                Text("Back to Library")
                    .foregroundColor(Color(AppColors.vampireBlack))
                    .font(.custom("Inter-SemiBold", size: 17))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(AppColors.vampireBlack), lineWidth: 1)
                    )
                    .background(Color.white) // Add background color if needed
            }
            Spacer()
        }
    }
}

struct UploadView: View {
    //@Environment(\.dismiss) var dismiss
    @State var showError: Bool = false
    @State var canGeneratePlaylist: Bool = true
    @State var task: Task<Playlist, Error>? = nil
    private let onComplete: (Playlist) -> ()
    let image: UIImage
    init(im: UIImage, fn: @escaping (Playlist) -> ()) {
        image = im
        onComplete = fn
    }
    
    var body: some View {
        Group {
            if showError {
                UploadErrorView()
            } else if canGeneratePlaylist {
                SpinningVinylView()
            } else {
                PleaseSubscribeView()
            }
        }.task {
            do {
                canGeneratePlaylist = try await SubscriptionManager.canUserGeneratePlaylist()
            } catch {
                showError = true
                return
            }
            task = APIRunner().run(image: image)
            let result = await task?.result
            switch result {
            case .success(let playlist):
                print("Finished running job, dismissing")
                onComplete(playlist)
            case .failure(let error):
                print("Error in running job: \(error.localizedDescription)")
                showError = true
            case .none:
                showError = true
            }
        }
    }
}

#Preview {
    UploadView(im: UIImage(), fn: {_ in})
}
