//
//  Artist.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import Foundation

struct Artist : Codable {
    let id: String
    let name: String
    let type: String
    let external_urls: [String: String]
}
