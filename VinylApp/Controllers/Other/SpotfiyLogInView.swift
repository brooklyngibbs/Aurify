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
    @State private var userName: String = ""
    @State private var textOffset1: CGFloat = -UIScreen.main.bounds.width
    @State private var textOffset2: CGFloat = -UIScreen.main.bounds.width
    @State private var buttonOpacity: Double = 0
    @State private var isUserNameLoaded: Bool = false
    @State private var navigateToTakeMeToAurify = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    if isUserNameLoaded {
                        Text("Hey \(userName),")
                            .foregroundColor(.white)
                            .font(.custom("PlayfairDisplay-Bold", size: 40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, geometry.size.width * 0.05)
                            .offset(x: textOffset1)
                            .padding(.top, 20)
                    }
                    Spacer()
                    SpotifyInformation(width: geometry.size.width)
                        .offset(x: textOffset2)
                        .padding(.top, geometry.size.height * 0.12)
                    Spacer()
                    VStack(spacing: 0) {
                        Spacer()
                        Button(action: {
                            showingAuthView = true
                        }) {
                            Text("CONNECT WITH SPOTIFY")
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
                        .padding(.top, geometry.size.height * 0.1)
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
                                            navigateToTakeMeToAurify = true
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
                        .opacity(buttonOpacity)
                        Button(action: {
                            Analytics.logEvent("no_spotify_log_in", parameters: nil)
                            navigateToTakeMeToAurify = true
                        }) {
                            Text("USE WITHOUT SPOTIFY")
                                .padding(10)
                                .foregroundColor(Color(AppColors.moonstoneBlue))
                                .frame(width: UIScreen.main.bounds.width * 0.8)
                                .font(.custom("Outfit-Medium", size: 18))
                                .cornerRadius(20)
                                .kerning(1.8)
                                .padding(.bottom, 40)
                        }
                        .opacity(buttonOpacity)
                        NavigationLink(destination: TakeMeToAurifyView(), isActive: $navigateToTakeMeToAurify) {
                            EmptyView()
                        }
                    }
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Oops"), message: Text("Something went wrong when signing in"), dismissButton: .cancel())
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            fetchUserName()
        }
    }
    
    func fetchUserName() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user name: \(error)")
            } else if let document = document, document.exists {
                isUserNameLoaded = true
                userName = document.get("name") as? String ?? "User"
                
                withAnimation(Animation.easeOut(duration: 0.8).delay(0.8)) {
                    textOffset1 = 10
                }
                withAnimation(Animation.easeOut(duration: 0.8).delay(1.2)) {
                    textOffset2 = 10
                }
                withAnimation(Animation.easeOut(duration: 0.8).delay(1.6)) {
                    buttonOpacity = 1
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}


struct SpotifyInformation: View {
    var width: CGFloat
    
    var body: some View {
        VStack {
            HStack {
                Text("Connect to Spotify to:")
                    .foregroundColor(.white)
                    .font(.custom("PlayfairDisplay-Bold", size: 30))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(.leading, width * 0.05)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("♫  Save your playlists in Spotify")
                    .foregroundColor(.white)
                    .font(.custom("PlayfairDisplay-Bold", size: 18))
                Text("♫  Get more personalized recommendations")
                    .foregroundColor(.white)
                    .font(.custom("PlayfairDisplay-Bold", size: 18))
                Text("♫  Share your playlists with others")
                    .foregroundColor(.white)
                    .font(.custom("PlayfairDisplay-Bold", size: 18))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.all, 20)
        }
    }
}


