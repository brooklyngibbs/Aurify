//
//  AlbumDetailsResponse.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import Foundation

struct AlbumDetailsResponse: Codable {
    let album_type: String
    let artists: [Artist]
    let available_markets: [String]
    let external_urls: [String: String]
    let id: String
    let images: [APIImage]
    let label: String
    let name: String
    let tracks: AudioTrack
}

struct TracksResponse: Codable {
    let items: [AudioTrack]
}
