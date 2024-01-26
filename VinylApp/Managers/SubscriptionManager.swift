import Foundation
import StoreKit

public class SubscriptionManager {
    public static let shared = SubscriptionManager() 

    public enum SubscriptionType: String {
        case none
        case fullAccess
    }

    private init() {}

    static func getSubscriptionType() async throws -> SubscriptionType {
        do {
            let productIds = ["AurifyFullAccess"]
            let products = try await Product.products(for: productIds)
            
            for product in products {
                if let status = try await product.subscription?.status {
                    if status.isEmpty {
                        UserDefaults.standard.set("None", forKey: "SubscriptionType")
                        return .none
                    }
                    if status[0].state == .subscribed, product.id == "AurifyFullAccess" {
                        UserDefaults.standard.set("FullAccess", forKey: "SubscriptionType")
                        return .fullAccess
                    }
                }
            }
            throw NSError(domain: "Subscription information not found", code: 0)
        } catch {
            throw error
        }
    }
    
    static func canUserGeneratePlaylist() async throws -> Bool {
        let subscriptionType = try await getSubscriptionType()
        switch subscriptionType {
        case .fullAccess:
            return true
        case .none:
            if let userId = UserDefaults.standard.value(forKey: "user_id") as? String {
                let count = try await withCheckedThrowingContinuation { continuation in
                    FirestoreManager().fetchPlaylistCount(forUserID: userId) { result in
                        continuation.resume(with: result)
                    }
                }
                return count == 0
            }
            throw NSError(domain: "Could not get user id", code: 0)
        }
    }
}
