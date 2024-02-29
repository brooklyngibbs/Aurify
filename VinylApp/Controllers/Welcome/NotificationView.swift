import SwiftUI
import Firebase
import FirebaseAnalytics

struct NotificationView: View {
    
    @State private var navigateToTakeMeToAurify = false
    @State private var textOffset1: CGFloat = -UIScreen.main.bounds.width
    @State private var textOffset2: CGFloat = -UIScreen.main.bounds.width
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                Spacer()
                VStack {
                    Text("Stay updated on:")
                        .foregroundColor(.white)
                        .font(.custom("PlayfairDisplay-Bold", size: 40))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(x: textOffset1)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 0.8).delay(0.5)) {
                                textOffset1 = 10
                            }
                        }
                        .padding(.leading, geometry.size.width * 0.05)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    NotificationInformation(width: geometry.size.width)
                        .offset(x: textOffset2)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 0.8).delay(0.7)) {
                                textOffset2 = 10
                            }
                            withAnimation(Animation.easeInOut(duration: 0.5).delay(0.9)) {
                                buttonOpacity = 1
                            }
                        }
                        .padding(.top, geometry.size.height * 0.12)
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        Spacer()
                        Button(action: {
                            requestNotificationPermission()
                        }) {
                            Text("TURN ON NOTIFICATIONS")
                                .padding(10)
                                .foregroundColor(.white)
                                .frame(width: UIScreen.main.bounds.width * 0.8)
                                .background(
                                    RadialGradient(
                                        gradient: Gradient(colors: [Color(AppColors.moonstoneBlue), Color(AppColors.radial_color)]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 100
                                    )
                                )
                                .font(.custom("Outfit-Medium", size: 18))
                                .cornerRadius(20)
                                .kerning(1.8)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        )
                        .opacity(buttonOpacity)
                        .padding(.top, geometry.size.height * 0.1)
                        
                        Button(action: {
                            Analytics.logEvent("no_notifications", parameters: nil)
                            navigateToTakeMeToAurify = true
                        }) {
                            Text("SKIP FOR NOW")
                                .padding(10)
                                .foregroundColor(Color(AppColors.moonstoneBlue))
                                .frame(width: UIScreen.main.bounds.width * 0.8)
                                .font(.custom("Outfit-Medium", size: 18))
                                .cornerRadius(20)
                                .kerning(1.8)
                                .padding(.bottom, 40)
                        }
                        
                        NavigationLink(destination: WelcomeSignInView(), isActive: $navigateToTakeMeToAurify) {
                            EmptyView()
                        }
                    }
                    .opacity(buttonOpacity)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(AppColors.dark_moonstone), Color.white]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Failed to request authorization for notifications: \(error.localizedDescription)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    navigateToTakeMeToAurify = true
                }
            }
        }
    }
}

struct NotificationInformation: View {
    var width: CGFloat
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("♫  Daily themes for photo uploads")
                    .foregroundColor(.white)
                    .font(.custom("PlayfairDisplay-Bold", size: 18))
                Text("♫  New updates and features")
                    .foregroundColor(.white)
                    .font(.custom("PlayfairDisplay-Bold", size: 18))
                Text("♫  Messages, comments, or mentions")
                    .foregroundColor(.white)
                    .font(.custom("PlayfairDisplay-Bold", size: 18))
                Text("♫  Stay up-to-date with friends")
                    .foregroundColor(.white)
                    .font(.custom("PlayfairDisplay-Bold", size: 18))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.all, 20)
        }
    }
}
