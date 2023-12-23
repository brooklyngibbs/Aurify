//
//  Playlist.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import Foundation
import FirebaseFirestoreInternal

struct Playlist: Codable, Identifiable {
    
    let description: String?
    let external_urls: [String: String]?
    let id: String
    let images: [APIImage]
    let name: String
    let owner: User
    let uri: String
    var isAppGenerated: Bool?
    var timestamp: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case description, external_urls, id, images, name, owner, uri
        case isAppGenerated = "isAppGenerated" 
    }
}

struct PlaylistResponse: Codable {
    let playlist: [Playlist]
}

struct User: Codable {
    let display_name: String
    let external_urls: [String: String]?
    let id: String
}
