//
//  FirebasePlaylist.swift
//  VinylApp
//
//  Created by Tanton Gibbs on 1/25/24.
//

import Foundation

struct FirebasePlaylist : Codable {
    let playlistId: String
    let coverImageUrl: String
    let name: String
    let images: [APIImage]
    let externalUrls: [String : String]
    let deleted: Bool?
    
    init(playlistId: String, coverImageUrl: String, name: String, images: [APIImage], externalUrls: [String : String], deleted: Bool?) {
        self.playlistId = playlistId
        self.coverImageUrl = coverImageUrl
        self.name = name
        self.images = images
        self.externalUrls = externalUrls
        self.deleted = deleted
    }
    
    enum CodingKeys : String, CodingKey {
        case playlistId = "id"
        case coverImageUrl = "cover_image_url"
        case deleted = "deleted"
        case name = "name"
        case images = "images"
        case externalUrls = "external_urls"
    }
}
