//
//  RecommendedTrackCellViewModel.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import Foundation

struct RecommendedTrackCellViewModel {
    let id = UUID()
    let name: String
    let artistName: String
    let artworkURL: URL?
    let previewUrl: String
    var isTrackTapped = false
}
