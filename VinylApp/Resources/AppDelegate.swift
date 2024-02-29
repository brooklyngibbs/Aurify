import UIKit
import SwiftUI
import Firebase
import UserNotifications
import FirebaseMessaging
import RevenueCat

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: APICaller.Constants.revenueKey)
        Purchases.shared.delegate = self
        
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        // Set up messaging delegate
        Messaging.messaging().delegate = self

        // Set up the initial window
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.setRootViewController()
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        
        // Subscribe to the "dailyTheme" topic
        Messaging.messaging().subscribe(toTopic: "dailyTheme") { error in
            if let error = error {
                print("Error subscribing to topic: \(error.localizedDescription)")
            } else {
                print("Subscribed to dailyTheme topic")
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func setRootViewController() {
        if let currentUser = Auth.auth().currentUser {
            print("User is signed in with UID: \(currentUser.uid)")
            self.window?.rootViewController = TabBarViewController()
        } else {
            print("No user is signed in.")
            let accountView = LogInView()
            let hostingController = UIHostingController(rootView: accountView)
            let navVC = UINavigationController(rootViewController: hostingController)
            navVC.navigationBar.prefersLargeTitles = true
            navVC.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always
            self.window?.rootViewController = navVC
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

}

extension AppDelegate: MessagingDelegate {

    // Handle FCM token refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        //print("Firebase registration token: \(String(describing: fcmToken))")
    }

}

extension AppDelegate: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task {
            do {
                if let entitlement = customerInfo.entitlements.all["fullAccess"], entitlement.isActive {
                    try await SubscriptionManager.getSubscriptionType()
                    print("User is premium!")
                } else {
                    // User is not "premium" or entitlement is not active
                    try await SubscriptionManager.getSubscriptionType()
                    print("User is not premium.")
                }
            } catch {
                print("Error fetching subscription type: \(error.localizedDescription)")
            }
        }
    }
}
