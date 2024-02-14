import SwiftUI
import MarqueeText

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
                            Text("Aurify")
                                .font(.custom("Outfit-Bold", size: 80))
                                .foregroundColor(Color.black)
                        }
                        .padding(.leading, 50)
                        .padding(.bottom, 60)
                    }
                    Button(action: {
                        showingAuthView = true
                    }) {
                        Text("Connect to Spotify")
                            .font(.custom("Inter-Light", size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(AppColors.moonstoneBlue))
                            .cornerRadius(30)
                    }
                    .sheet(isPresented: $showingAuthView) {
                        AuthViewControllerWrapper(isPresented: $showingAuthView, loginCompletion: { success in
                            if success {
                                // Once authentication succeeds, get the user profile
                                APICaller.shared.getCurrentUserProfile { result in
                                    switch result {
                                    case .success(let userProfile):
                                        // Set the user_id here
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
    }
}
