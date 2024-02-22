//
//  FirebasePlaylist.swift
//  VinylApp
//
//  Created by Tanton Gibbs on 1/25/24.
//

import Foundation

struct FirebasePlaylist : Codable {
    let playlistId: String
    let spotifyId: String
    let coverImageUrl: String
    let name: String
    let images: [String]
    let externalUrls: [String : String]
    let deleted: Bool?
    let playlistDetails: [CleanSongInfo]
    let liked: Bool?
    
    init(playlistId: String, spotifyId: String, coverImageUrl: String, name: String, images: [String], externalUrls: [String : String], playlistDetails: [CleanSongInfo], deleted: Bool?, liked: Bool?) {
        self.playlistId = playlistId
        self.spotifyId = spotifyId
        self.coverImageUrl = coverImageUrl
        self.name = name
        self.images = images
        self.externalUrls = externalUrls
        self.deleted = deleted
        self.playlistDetails = playlistDetails
        self.liked = liked
    }
    
    enum CodingKeys : String, CodingKey {
        case playlistId = "id"
        case spotifyId = "spotify_id"
        case coverImageUrl = "cover_image_url"
        case deleted = "deleted"
        case name = "name"
        case images = "images"
        case externalUrls = "external_urls"
        case playlistDetails = "playlist_info"
        case liked = "liked"
    }
}
