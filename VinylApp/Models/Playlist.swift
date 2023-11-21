//
//  Playlist.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import Foundation

struct Playlist: Codable {
    let description: String?
    let external_urls: [String: String]?
    let id: String
    let images: [APIImage]
    let name: String
    let owner: User
    let uri: String
}

struct PlaylistResponse: Codable {
    let playlist: [Playlist]
}

struct User: Codable {
    let display_name: String
    let external_urls: [String: String]?
    let id: String
}
