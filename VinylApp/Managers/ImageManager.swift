//
//  ImageManager.swift
//  VinylApp
//
//  Created by Tanton Gibbs on 1/21/24.
//

import Foundation
import FirebaseStorage

class ImageManager {
    
    let originalImage: UIImage
    var currentImage: UIImage
    
    init(_ im: UIImage) {
        originalImage = im
        currentImage = im
    }
    
    init(_ imUrl: URL) async throws {
        let (data, response) = try await URLSession.shared.data(from: imUrl)
        originalImage = UIImage(data: data)!
        currentImage = originalImage
    }
    
    func resizeImage(targetSize: CGSize) -> ImageManager {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        currentImage = renderer.image { context in
            currentImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return self
    }
    
    func convertImageToBase64(maxBytes: Int) throws -> String {
        var compression = 1.0
        var base64String = ""
        if let resizedImageData = currentImage.jpegData(compressionQuality: compression) {
            base64String = resizedImageData.base64EncodedString()
            print("Size: \(base64String.count)")
            while base64String.count > maxBytes {
                compression -= 0.2
                if compression >= 0,
                   let resizedImageData = currentImage.jpegData(compressionQuality: compression) {
                    print("Size: \(base64String.count)")
                    base64String = resizedImageData.base64EncodedString()
                } else {
                    throw NSError(domain: "Could not convert image to base64", code: 0)
                }
            }
        }
        return base64String
    }
    
    func uploadImageToStorage() async throws -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "\(timestamp)_\(UUID().uuidString)"
        let imageData = currentImage.jpegData(compressionQuality: 1.0)!
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let storageRef = Storage.storage().reference().child("images/\(uniqueFileName).jpeg")
        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(imageData, metadata: metadata) { (metadata, error) in
                if let error = error {
                    print("Failed to upload: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                storageRef.downloadURL() { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    if let url = url {
                        continuation.resume(returning: url.absoluteString)
                        return
                    }
                }
            }
        }
    }
}
