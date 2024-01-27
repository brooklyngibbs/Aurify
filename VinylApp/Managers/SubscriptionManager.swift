import Foundation
import RevenueCat
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
            let customerInfo = try await Purchases.shared.customerInfo()

            if customerInfo.entitlements.all["fullAccess"]?.isActive == true {
                UserDefaults.standard.set("FullAccess", forKey: "SubscriptionType")
                return .fullAccess
            }
            UserDefaults.standard.set("None", forKey: "SubscriptionType")
            return .none
        } catch {
            // Log detailed error information for debugging
            print("Error in getSubscriptionType: \(error.localizedDescription)")
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
