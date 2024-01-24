//
//  ImageInfo.swift
//  VinylApp
//
//  Created by Tanton Gibbs on 1/24/24.
//

import Foundation

struct ImageInfo: Codable {
    var description: String
    var playlistTitle: String
    var music: String?
    var genre: String
    var subgenre: String
    var mood: String
    var songlist: [SongInfo]
}
