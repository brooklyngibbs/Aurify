//
//  APICallerr.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import Foundation


final class APICaller {
    
    static let shared = APICaller()
    
    private init() {}
    
    struct Constants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }
    
    enum APIError: Error {
        case failedToGetData
    }
    
    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me"), type: .GET) { baseRequest in
            let task = URLSession.shared.dataTask(with: baseRequest) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(UserProfile.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    //MARK: - Playback
    
    func getPlaybackState(completion: @escaping (Bool?) -> Void) {
        guard let url = URL(string: "https://api.spotify.com/v1/me/player") else {
            completion(nil)
            return
        }

        createRequest(with: url, type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error fetching playback state: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let data = data, !data.isEmpty else {
                    completion(false) // Return false when the data is empty
                    return
                }

                do {
                    // Parse the JSON response to retrieve the 'is_playing' state
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let isPlaying = json?["is_playing"] as? Bool
                    completion(isPlaying)
                } catch {
                    print("Error parsing JSON: \(error)")
                    completion(nil)
                }
            }
            task.resume()
        }
    }
    
    func startPlaybackRequest(with contextURI: String) {
        let url = URL(string: "https://api.spotify.com/v1/me/player/play")!

        let requestBody: [String: String] = ["context_uri": contextURI]

        do {
            let requestData = try JSONSerialization.data(withJSONObject: requestBody)

            createRequest(with: url, type: .PUT) { request in
                var requestCopy = request
                requestCopy.httpBody = requestData

                let task = URLSession.shared.dataTask(with: requestCopy) { data, response, error in

                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode != 204 {
                            print("Error: Unexpected status code - \(httpResponse.statusCode)")
                        }
                    }
                }
                task.resume()
            }
        } catch {
            print("Error: JSON serialization failed - \(error)")
        }
    }
    
    func startPlaybackRequestByTrack(with contextURI: String, offset: Int) {
        let url = URL(string: "https://api.spotify.com/v1/me/player/play")!

        let requestBody: [String: Any] = [
                "context_uri": contextURI,
                "offset": [
                    "position": offset
                ]
            ]

        do {
            let requestData = try JSONSerialization.data(withJSONObject: requestBody)

            createRequest(with: url, type: .PUT) { request in
                var requestCopy = request
                requestCopy.httpBody = requestData

                let task = URLSession.shared.dataTask(with: requestCopy) { data, response, error in

                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode != 204 {
                            print("Error: Unexpected status code - \(httpResponse.statusCode)")
                        }
                    }
                }
                task.resume()
            }
        } catch {
            print("Error: JSON serialization failed - \(error)")
        }
    }
    
    func shuffleSpotifyPlayer(state: Bool) {
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/shuffle?state=\(state)") else {
            return
        }

        createRequest(with: url, type: .PUT) { request in
            var requestCopy = request
            requestCopy.httpMethod = "PUT"

            let task = URLSession.shared.dataTask(with: requestCopy) { data, response, error in
                if let error = error {
                    print("Error shuffling Spotify player: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 204 {
                        print("Error: Unexpected status code - \(httpResponse.statusCode)")
                    }
                }
            }
            task.resume()
        }
    }
    
    //MARK: - Playlists
    
    public func getPlaylistDetails(for playlist: Playlist, completion: @escaping (Result<PlaylistDetailsResponse, Error>) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/playlists/" + playlist.id),
            type: .GET
        ) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(PlaylistDetailsResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    print(error)
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func getCurrentUserPlaylists(completion: @escaping (Result<[Playlist], Error>) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/me/playlists/?limit=50"),
            type: .GET
        ) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(LibraryPlaylistsResponse.self, from: data)
                    completion(.success(result.items))
                }
                catch {
                    print(error)
                    completion(.failure(error))
                }
            }
            task.resume()
            
        }
    }
    
    func updatePlaylistImage(imageBase64: String, playlistID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://api.spotify.com/v1/playlists/\(playlistID)/images"

        guard let url = URL(string: urlString) else {
            let urlError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(urlError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

        AuthManager.shared.withValidToken { token in
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 120

        guard let imageData = imageBase64.data(using: .utf8) else {
            print("image data null")
            return 
        }

        request.httpBody = imageData // Set image data as the request body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 202 {
                    completion(.success(())) // Successful image update
                } else if httpResponse.statusCode == 400 {
                    if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                        print("Response data for 400 error:", responseString)
                    }
                    let statusCodeError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Bad request: \(httpResponse.statusCode)"])
                    completion(.failure(statusCodeError)) // Handle 400 status code
                } else {
                    let statusCodeError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected status code: \(httpResponse.statusCode)"])
                    completion(.failure(statusCodeError)) // Handle unexpected status code
                }
            }
        }

        task.resume()
    }
    
    public func getArtistURI(artist: String, completion: @escaping (Result<String, Error>) -> Void) {
        let formattedQuery = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = Constants.baseAPIURL + "/search?q=\(formattedQuery)&type=artist&limit=1"
        createRequest(
            with: URL(string: urlString),
            type: .GET
        ) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let artists = json["artists"] as? [String: Any],
                       let items = artists["items"] as? [[String: Any]],
                       let firstItem = items.first,
                       let uri = firstItem["uri"] as? String {
                           
                       completion(.success(uri))
                    } else {
                        completion(.failure(APIError.failedToGetData))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func addTrackToPlaylist(trackURI: String, playlist_id: String, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = Constants.baseAPIURL + "/playlists/\(playlist_id)/tracks"
        
        createRequest(with: URL(string: urlString), type: .POST) { baseRequest in
            var request = baseRequest
            let json = [
                "uris": [trackURI]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    completion(.failure(error ?? APIError.failedToGetData))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                    // If the status code is 201 (Created), extract playlist ID from the response
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        if let snapshotID = json?["snapshot_id"] as? String {
                            completion(.success(snapshotID))
                        } else {
                            completion(.failure(APIError.failedToGetData))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(APIError.failedToGetData))
                }
            }
            task.resume()
        }
    }
    
    public func addTrackArrayToPlaylist(trackURI: [String], playlist_id: String, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = Constants.baseAPIURL + "/playlists/\(playlist_id)/tracks"
        
        createRequest(with: URL(string: urlString), type: .POST) { baseRequest in
            var request = baseRequest
            let json = [
                "uris": trackURI
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    completion(.failure(error ?? APIError.failedToGetData))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                    // If the status code is 201 (Created), extract playlist ID from the response
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        if let snapshotID = json?["snapshot_id"] as? String {
                            completion(.success(snapshotID))
                        } else {
                            completion(.failure(APIError.failedToGetData))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(APIError.failedToGetData))
                }
            }
            task.resume()
        }
    }

    public func searchSong(q: SongInfo, playlist_id: String, completion: @escaping (Result<String, Error>) -> Void) {
        let formattedQ = ("artist:\(q.artist)&title:\(q.title)").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = Constants.baseAPIURL + "/search?q=\(formattedQ)&type=track&limit=1"

        createRequest(with: URL(string: urlString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let tracks = json["tracks"] as? [String: Any],
                       let items = tracks["items"] as? [[String: Any]],
                       let firstItem = items.first,
                       let uri = firstItem["uri"] as? String {
                        
                        completion(.success(uri))
                    } else {
                        completion(.failure(APIError.failedToGetData))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }


    public func getPlaylist(with playlist_id: String, completion: @escaping (Result<Playlist, Error>) -> Void) {
        let urlString = Constants.baseAPIURL + "/playlists/\(playlist_id)"
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.failedToGetData))
            return
        }

        createRequest(with: url, type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(error ?? APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(Playlist.self, from: data)
                    completion(.success(result))
                } catch {
                    print("Error decoding Playlist:", error)
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }


    public func createPlaylist(with name: String, description: String, completion: @escaping (Result<Playlist, Error>) -> Void) {
        getCurrentUserProfile { [weak self] result in
            switch result {
            case .success(let profile):
                let urlString = Constants.baseAPIURL + "/users/\(profile.id)/playlists"
                
                self?.createRequest(with: URL(string: urlString), type: .POST) { baseRequest in
                    var request = baseRequest
                    let json = [
                        "name": name
                    ]
                    request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
                    
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        guard let data = data, error == nil else {
                            completion(.failure(error ?? APIError.failedToGetData))
                            return
                        }
                        
                        do {
                            let result = try JSONDecoder().decode(Playlist.self, from: data)
                            completion(.success(result))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                    task.resume()
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    enum HTTPMethod: String {
        case GET
        case POST
        case PUT
    }
    
    private func createRequest(with url: URL?, type: HTTPMethod, completion: @escaping (URLRequest) -> Void) {
        AuthManager.shared.withValidToken { token in
            guard let apiURL = url else {
                return
            }
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            completion(request)
        }
    }
}
