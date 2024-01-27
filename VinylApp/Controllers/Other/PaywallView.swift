import SwiftUI
import RevenueCat

struct PaywallView: View {
    @State private var offering: Offering?

    var body: some View {
        HStack {
            Spacer()
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                Image("clean-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(15) 
                    .padding()
                
                if let monthlyFullAccessPackage = offering?.availablePackages.first(where: { $0.identifier == "fullAccess" }) {
                    VStack {
                        Text(monthlyFullAccessPackage.storeProduct.localizedTitle)
                            .font(Font.custom("Outfit-Bold", size: 24))
                            .padding()

                        Text(monthlyFullAccessPackage.localizedPriceString)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }

                Spacer()

                ForEach(offering?.availablePackages.filter { $0.identifier != "fullAccess" } ?? [], id: \.identifier) { package in
                    SquareListItem(package: package)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()

                Spacer()
                
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
            .frame(maxWidth: .infinity)

            Spacer()
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
        } else {
            Task {
                do {
                    let subscriptionType = try await SubscriptionManager.getSubscriptionType()
                    print("Subscription Type: \(subscriptionType)") // Add this line to print the subscription type

                    if subscriptionType == .fullAccess {
                        print("Pro content unlocked!")
                    } else {
                        print("Purchase completed, but content not unlocked.")
                    }
                } catch {
                    print("Error fetching subscription type: \(error.localizedDescription)")
                }
            }
        }
    }

}

struct SquareListItem: View {
    let package: Package

    var body: some View {
        VStack {
            Text(package.storeProduct.localizedTitle)
                .foregroundColor(.primary)
                .font(Font.custom("Outfit-Bold", size: 24))
                .multilineTextAlignment(.center)
                .padding(8)
            
            Text("\(package.localizedPriceString) / month")
                .foregroundColor(.secondary)
                .font(.caption)
                .padding(.bottom, 4)

            Text("Unlock unlimited playlists")
                .foregroundColor(.secondary)
                .font(.caption)
                .padding(.bottom, 4)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 2).background(RoundedRectangle(cornerRadius: 8).foregroundColor(Color.gray.opacity(0.2))))
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
