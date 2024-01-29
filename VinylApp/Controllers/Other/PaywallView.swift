import SwiftUI
import RevenueCat

struct PaywallView: View {
    @State private var offering: Offering?
    @State private var isSubscribed: Bool = false

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
                            .foregroundColor(Color(AppColors.vampireBlack))

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
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(isSubscribed ? .gray : Color(AppColors.moonstoneBlue)))
                        .disabled(isSubscribed)
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
                    
                HStack {
                    Button(action: linkToPrivacyPolicy) {
                        Text("Privacy Policy")
                            .foregroundColor(.secondary)
                            .font(Font.custom("Inter-Regular", size: 10))
                    }
                    Button(action: linkToTerms) {
                        Text("Terms & Conditions")
                            .foregroundColor(.secondary)
                            .font(Font.custom("Inter-Regular", size: 10))
                    }
                }
                .padding()
                Text("Payment will be charged to your ITunes account at confirmation of purchase. Subscriptions will automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged according to your plan for renewal within 24 hours prior to the end of your current period. You can manage or turn off auto-renew in your Apple ID account settings at any time after purchase.")
                    .foregroundColor(.secondary)
                    .font(Font.custom("Inter-Regular", size: 10))
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

                // Check subscription status
                Task {
                    do {
                        let subscriptionType = try await SubscriptionManager.getSubscriptionType()
                        isSubscribed = (subscriptionType == .fullAccess)
                    } catch {
                        print("Error fetching subscription type: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func linkToPrivacyPolicy() {
        guard let privacyPolicyURL = URL(string: "https://www.aurifyapp.com/privacy-policy") else {
            return
        }
        UIApplication.shared.open(privacyPolicyURL)
    }
    
    func linkToTerms() {
        guard let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else {
            return
        }
        UIApplication.shared.open(termsURL)
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
            Text("Aurify All Access")
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
