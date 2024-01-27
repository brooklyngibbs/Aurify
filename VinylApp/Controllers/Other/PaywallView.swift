import SwiftUI
import RevenueCat

struct PaywallView: View {
    @State private var offering: Offering?

    var body: some View {
        VStack {
            List {
                // Display the offerings in the list
                ForEach(offering?.availablePackages ?? [], id: \.identifier) { package in
                    Text("\(package.storeProduct.localizedTitle) - \(package.localizedPriceString )")
                }
            }
            .navigationTitle("Subscription Options")

            Button(action: purchaseButtonTapped) {
                Text("Purchase")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color(AppColors.moonstoneBlue)))
            }
            .padding()

            Button("Restore Purchases") {
                // Restore previous purchases
                Purchases.shared.restorePurchases { (customerInfo, error) in
                    handlePurchaseResult(customerInfo: customerInfo, error: error)
                }
            }
            .foregroundColor(Color(AppColors.moonstoneBlue))
            .padding()
        }
        .onAppear {
            Purchases.shared.getOfferings { (offerings, error) in
                if let error = error {
                    print(error.localizedDescription)
                }

                self.offering = offerings?.current
            }
        }
    }

    func purchaseButtonTapped() {
        guard let package = offering?.availablePackages.first else {
            print("No available packages.")
            return
        }

        Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
            handlePurchaseResult(customerInfo: customerInfo, error: error)
        }
    }

    func handlePurchaseResult(customerInfo: CustomerInfo?, error: Error?) {
        if let error = error {
            print("Purchase error: \(error.localizedDescription)")
            // Handle purchase error if needed
        } else {
            Task {
                do {
                    let subscriptionType = try await SubscriptionManager.getSubscriptionType()
                    if subscriptionType == .fullAccess {
                        print("Pro content unlocked!")
                    } else {
                        print("Purchase completed, but content not unlocked.")
                    }
                } catch {
                    print("Error fetching subscription type: \(error.localizedDescription)")
                    // Handle error if needed
                }
            }
        }
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
