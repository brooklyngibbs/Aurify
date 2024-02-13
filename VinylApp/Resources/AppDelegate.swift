//
//  AppDelegate.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/19/23.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import RevenueCat

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: APICaller.Constants.revenueKey)
        Purchases.shared.delegate = self
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        if AuthManager.shared.isSignedIn {
            AuthManager.shared.refreshIfNeeded(completion: nil)
            window.rootViewController = TabBarViewController()
        } else if Auth.auth().currentUser != nil {
            window.rootViewController = TabBarViewController()
        } else {
            let accountView = LogInView()
            let hostingController = UIHostingController(rootView: accountView)
            let navVC = UINavigationController(rootViewController: hostingController)
            navVC.navigationBar.prefersLargeTitles = true
            navVC.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always
            window.rootViewController = navVC
        }
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
    

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
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

