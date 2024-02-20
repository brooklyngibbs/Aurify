import SwiftUI
import Firebase
import FirebaseAnalytics

struct AuthViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var loginCompletion: ((Bool) -> Void)?
    
    func makeUIViewController(context: Context) -> AuthViewController {
        let authVC = AuthViewController()
        authVC.completionHandler = { success in
            DispatchQueue.main.async {
                self.isPresented = false
                loginCompletion?(success)
            }
        }
        return authVC
    }
    
    func updateUIViewController(_ uiViewController: AuthViewController, context: Context) {
        // Update the view controller if needed
    }
}

struct SpotifyLogInView: View {
    @State private var showingAuthView = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ZStack {
                        GeometryReader { imageGeometry in
                            Image("gradient1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: geometry.size.height * 0.9)
                                .edgesIgnoringSafeArea(.top)
                        }
                        .frame(height: geometry.size.height * 0.8)
                        .padding(.top, -30)
                        VStack {
                            Text("Welcome to")
                                .font(.custom("Outfit-Bold", size: 30))
                                .foregroundColor(Color.black)
                                .padding(.top, 50)
                                .padding(.leading, -180)
                                .shadow(
                                    color: Color.primary.opacity(0.3), /// shadow color
                                    radius: 3, /// shadow radius
                                    x: 0, /// x offset
                                    y: 2 /// y offset
                                )
                            Text("Aurify")
                                .font(.custom("Outfit-Bold", size: 80))
                                .foregroundColor(Color.black)
                                .shadow(
                                    color: Color.primary.opacity(0.3), /// shadow color
                                    radius: 3, /// shadow radius
                                    x: 0, /// x offset
                                    y: 2 /// y offset
                                )
                        }
                        .padding(.leading, 50)
                        .padding(.bottom, 60)
                    }

                    TypingAnimationView()
                        .padding(.top, -20)

                    Spacer()
                    
                    Button(action: {
                        showingAuthView = true
                    }) {
                        Text("Connect to Spotify")
                            .font(.custom("Inter-Light", size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .cornerRadius(30)
                            .background(RoundedRectangle(cornerRadius: 30)
                                            .fill(Color(AppColors.moonstoneBlue))
                                            .shadow(color: .gray, radius: 8, x: 0, y: 5)
                            )
                    }
                    .sheet(isPresented: $showingAuthView) {
                        AuthViewControllerWrapper(isPresented: $showingAuthView, loginCompletion: { success in
                            if success {
                                // Once authentication succeeds, get the user profile
                                APICaller.shared.getCurrentUserProfile { result in
                                    switch result {
                                    case .success(let userProfile):
                                        // Set the user_id here
                                        Analytics.logEvent("spotify_log_in", parameters: nil)
                                        print("Setting user default \(userProfile.id)")
                                        UserDefaults.standard.set(userProfile.id, forKey: "user_id")
                                        DispatchQueue.main.async {
                                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                                if let window = windowScene.windows.first {
                                                    window.rootViewController = TabBarViewController()
                                                    window.makeKeyAndVisible()
                                                }
                                            }
                                        }
                                        // Handle further navigation or actions
                                    case .failure(let error):
                                        // Handle the failure to get the user profile
                                        Analytics.logEvent("spotify_account_fetch_error", parameters: nil)
                                        print("Error fetching user profile: \(error)")
                                        showAlert = true
                                    }
                                }
                            } else {
                                // Handle login failure
                                showAlert = true
                            }
                        })
                    }
                    
                    Button(action: {
                        Analytics.logEvent("no_spotify_log_in", parameters: nil)
                        DispatchQueue.main.async {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                if let window = windowScene.windows.first {
                                    window.rootViewController = TabBarViewController()
                                    window.makeKeyAndVisible()
                                }
                            }
                        }
                    }) {
                        Text("Use without Spotify")
                            .font(.custom("Inter-Light", size: 20))
                            .foregroundColor(Color(AppColors.moonstoneBlue))
                            .padding()
                    }
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(true)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .navigationBarHidden(true)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Oops"), message: Text("Something went wrong when signing in"), dismissButton: .cancel())
        }
        Spacer()
    }
}

struct TypingAnimationView: View {
    let textToType = "✨Capture Moments. Curate Playlists.✨"
    @State private var animatedText: String = ""

    var body: some View {
        VStack {
            Text(animatedText)
                .font(.custom("Inter-Light", size: 18))
                .foregroundColor(Color.gray)
                .padding()

        }
        .onAppear {
            animateText()
        }
    }

    func animateText() {
        for (index, character) in textToType.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                animatedText.append(character)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

struct TypingAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        TypingAnimationView()
    }
}
