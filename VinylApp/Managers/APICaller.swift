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
                    //print(result)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    //MARK: - Playback
    func startPlaybackRequest(with contextURI: String) {
        // Create the URL for starting playback.
        let url = URL(string: "https://api.spotify.com/v1/me/player/play")!

        // Create the request body as a dictionary.
        let requestBody: [String: String] = ["context_uri": contextURI]

        // Serialize the request body to JSON data.
        do {
            let requestData = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Use the createRequest function to create a URLRequest.
            createRequest(with: url, type: .PUT) { request in
                var requestCopy = request // Create a mutable copy of the request
                requestCopy.httpBody = requestData

                // Create a URLSession data task for the request.
                let task = URLSession.shared.dataTask(with: requestCopy) { data, response, error in
                    if let error = error {
                        print("Error: \(error)")
                        return
                    }

                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 204 {
                            // Status code 204 indicates a successful request.
                            print("Playback started successfully.")
                        } else {
                            print("Error: Unexpected status code - \(httpResponse.statusCode)")
                        }
                    }
                }

                // Start the data task to send the request.
                task.resume()
            }
        } catch {
            print("Error: JSON serialization failed - \(error)")
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
                    //print(json)
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


    public func searchSong(q: String, playlist_id: String, completion: @escaping (Result<String, Error>) -> Void) {
        let artistName = q.components(separatedBy: "by").last?.trimmingCharacters(in: .whitespaces) ?? ""
        print("Artist Name:", artistName)
        
        let formattedQuery = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        print("Formatted Query:", formattedQuery)
        
        let urlString = Constants.baseAPIURL + "/search?q=\(formattedQuery)&type=track&limit=50"
        print("URL:", urlString)
        
        createRequest(with: URL(string: urlString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let tracks = json["tracks"] as? [String: Any],
                       let items = tracks["items"] as? [[String: Any]] {
                        
                        // Fetch the URI of the artist
                        self.getArtistURI(artist: artistName) { result in
                            switch result {
                            case .success(let artistURI):
                                print("Artist URI:", artistURI)
                                
                                // Iterate through the track items and find the matching track URI for the artist
                                if let matchingTrack = items.first(where: { track in
                                    if let artists = track["artists"] as? [[String: Any]] {
                                        for artist in artists {
                                            if let artistURIFromTrack = artist["uri"] as? String {
                                                print("Comparing Artist URIs:", artistURIFromTrack)
                                                if artistURIFromTrack == artistURI {
                                                    return true
                                                }
                                            }
                                        }
                                    }
                                    return false
                                }) {
                                    if let trackURI = matchingTrack["uri"] as? String {
                                        completion(.success(trackURI))
                                    } else {
                                        completion(.failure(APIError.failedToGetData))
                                    }
                                } else {
                                    completion(.failure(APIError.failedToGetData))
                                }
                                
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
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
