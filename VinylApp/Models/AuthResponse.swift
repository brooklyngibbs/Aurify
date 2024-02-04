//
//  AuthResponse.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/22/23.
//

import Foundation

struct AuthResponse: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
    let token_type: String
}

struct ClientCredentialAccessToken: Codable {
    let access_token: String
}
