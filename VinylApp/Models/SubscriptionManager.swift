import Foundation
import StoreKit

public class SubscriptionManager {
    public static let shared = SubscriptionManager() // Singleton instance

    public enum SubscriptionType: String {
        case none
        case fullAccess
    }

    private init() {}

    static func getSubscriptionType() async throws -> SubscriptionType {
        let productIds = ["AurifyFullAccess"]
        let products = try await Product.products(for: productIds)
        for product in products {
            if let status = try await product.subscription?.status {
                if status.count == 0 {
                    UserDefaults.standard.set("None", forKey: "SubscriptionType")
                    return .none
                }
                if status[0].state == .subscribed {
                    if product.id == "AurifyFullAccess" {
                        UserDefaults.standard.set("FullAccess", forKey: "SubscriptionType")
                        return .fullAccess
                    }
                }
            }
        }
        return .none
    }
}
