//
//  Album.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import Foundation

struct Album: Codable {
    let album_type: String
    let available_markets: [String]
    let id: String
    let images: [APIImage]
    let name: String
    let total_tracks: Int
    let artists: [Artist]
    let uri: String
}

struct AlbumsResponse: Codable {
    let items: [Album]
}

