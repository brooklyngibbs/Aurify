//
//  SongInfo.swift
//  VinylApp
//
//  Created by Tanton Gibbs on 1/24/24.
//

import Foundation

struct SongInfo: Codable {
    var title: String
    var artist: String
    var reason: String
}

struct CleanSongInfo: Codable {
    var title: String
    var artistName: String
    var previewUrl: String
    var spotifyUri: String
    var artworkUrl: String
    
    init(title: String, artistName: String, previewUrl: String, spotifyUri: String, artworkUrl: String) {
        self.title = title
        self.artistName = artistName
        self.previewUrl = previewUrl
        self.spotifyUri = spotifyUri
        self.artworkUrl = artworkUrl
    }
    
    enum CodingKeys : String, CodingKey {
        case title = "title"
        case artistName = "artist"
        case previewUrl = "preview_url"
        case spotifyUri = "uri"
        case artworkUrl = "cover_image_url"
    }
}
