//
//  Upload2VC.swift
//  VinylApp
//
//  Created by Tanton Gibbs on 1/20/24.
//

import SwiftUI
import FirebaseAuth

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
    private let topArtists: [String] = []
    
    private func createAPIRequest(imageUrl: String) throws -> URLRequest {
        var request = URLRequest(url: APICaller.Constants.imageAPIURL)
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
    
    func run(image: UIImage) -> Task<FirebasePlaylist, Error> {
        let task = Task {
            let imageManager = ImageManager(image)
            print("Uploading to storage")
            let url = try await imageManager.uploadImageToStorage()
            print("Creating api request")
            let json = try await retry(times: 2) {
                let request = try createAPIRequest(imageUrl: url)
                let (data, _) = try await URLSession.shared.data(for: request)
                print("Decoding JSON")
                return try JSONDecoder().decode(ImageInfo.self, from: data)
            }
            print("Adding Tracks")
            var seenUris = Set<String>()
            let results = await APICaller.shared.searchManySongs(q: json.songlist).compactMap { try? $0.get() }.filter {
                seenUris.insert($0.spotifyUri).inserted
            }
            let songImages = results.map {$0.artworkUrl}
            print("Converting image")
            let userId = Auth.auth().currentUser!.uid
            let playlistId = try await FirestoreManager().savePlaylistToFirestore(userID: userId, name: json.playlistTitle, description: json.description, songInfo: results, imageUrl: url, imageInfo: json)
            return FirebasePlaylist(playlistId: playlistId, spotifyId: "", coverImageUrl: url, name: json.playlistTitle, images: songImages, externalUrls: [:], playlistDetails: results, deleted: nil)
        }
        return task
    }
}

struct SpinningVinylImage: View {
    @State private var degreesRotating = 0.0
    private var foreverAnimation : Animation {
        Animation.linear(duration: 1.0)
            .repeatForever(autoreverses: false)
    }
    var body: some View {
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
    }
}

struct LoadingView: View {
    var body: some View {
        Spacer()
        Spacer()
        SpinningVinylImage()
        Spacer()
        Spacer()
        Spacer()
    }
}

struct SpinningVinylView: View {
    @Environment(\.dismiss) var dismiss
    @State var degreesRotating = 0.0
    @State var generatingText = "Generating your picture playlist. Do not exit out of app"
    @State var labelTimer : Timer?
    @Binding var task: Task<FirebasePlaylist, Error>?
    var topArtists: [String] = []
    
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
        VStack(spacing: 40) {
            Spacer()
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
            Button(action: {
                task?.cancel()
                task = nil
                dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(Color(AppColors.vampireBlack))
                    .font(.custom("Inter-SemiBold", size: 17))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(AppColors.vampireBlack), lineWidth: 1)
                    )
                    .background(Color.white) // Add background color if needed
            }.disabled(task == nil)
            Spacer()
        }
    }
}

struct PleaseSubscribeView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            Spacer()
            Text("Subscribe")
                .font(.custom("Outfit-Bold", size: 27))
                .padding(5)
            Text("to get more of Aurify!")
                .font(.custom("Inter-Regular", size: 17))
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
    @State var showError: Bool = false
    @State var canGeneratePlaylist: Bool = true
    @State var task: Task<FirebasePlaylist, Error>? = nil
    private let onComplete: (FirebasePlaylist) -> ()
    let image: UIImage
    
    init(im: UIImage, fn: @escaping (FirebasePlaylist) -> ()) {
        image = im
        onComplete = fn
    }
    
    var body: some View {
        Group {
            if showError {
                UploadErrorView()
            } else if canGeneratePlaylist {
                SpinningVinylView(task: $task)
            } else {
                PleaseSubscribeView()
            }
        }.task {
            showError = false
            do {
                canGeneratePlaylist = try await SubscriptionManager.canUserGeneratePlaylist()
                guard canGeneratePlaylist else {
                    return
                }
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
