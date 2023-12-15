import SwiftUI

struct AuthViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var isPresented: Bool // Add a binding to control the presentation
    
    func makeUIViewController(context: Context) -> AuthViewController {
        let authVC = AuthViewController()
        authVC.completionHandler = { success in
            DispatchQueue.main.async {
                self.isPresented = false
                if success {
                    if let window = UIApplication.shared.windows.first {
                        window.rootViewController = TabBarViewController()
                        window.makeKeyAndVisible()
                    }
                }
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
                VStack {
                    Spacer()
                    
                    Image("spotify_image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: geometry.size.height * 0.4)
                        .edgesIgnoringSafeArea(.top)
                    
                    Text("Welcome to Soundtrak!")
                        .font(.custom("Outfit-Bold", size: 30))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(.top, 20)
                    
                    Button(action: {
                        showingAuthView = true
                    }) {
                        Text("Log in with Spotify")
                            .font(.custom("Inter-Light", size: 20))
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    }
                    .padding(.top, 60)
                    .sheet(isPresented: $showingAuthView) {
                        AuthViewControllerWrapper(isPresented: $showingAuthView)
                    }
                    
                    Spacer()
                }
                .navigationBarBackButtonHidden(true) // Hide the back button
                .navigationBarHidden(true)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color(red: 239.0/255.0, green: 235.0/255.0, blue: 226.0/255.0))
                .edgesIgnoringSafeArea(.all)
                .navigationBarHidden(true)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Oops"), message: Text("Something went wrong when signing in"), dismissButton: .cancel())
        }
    }
}
