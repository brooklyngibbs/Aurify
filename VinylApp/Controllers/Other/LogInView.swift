import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseCore
import FirebaseAnalytics

struct LogInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loginSuccess: Bool = false
    @State private var navigateToSpotifyLogin: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var resetEmail: String = ""
    @State private var resetPasswordSuccess: Bool = false
    @State private var showForgotPasswordAlert: Bool = false
    @State private var showEmailFieldForReset: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 20) {
                        Text("Aurify")
                            .font(.custom("Outfit-Bold", size: 40))
                            .frame(width: geometry.size.width * 0.8) // Adjust the width if needed
                            .padding(.bottom)
                        
                        TextField("Email", text: $email)
                            .frame(width: geometry.size.width * 0.75)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                            .font(.custom("Inter-Light", size: 20))
                        
                        SecureField("Password", text: $password)
                            .frame(width: geometry.size.width * 0.75)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                            .font(.custom("Inter-Light", size: 20))
                            .padding(.bottom)
                        
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .font(.custom("Inter-Medium", size: 15))
                                .frame(width: geometry.size.width * 0.75)
                                .padding(8)
                                .background(Color(AppColors.venetian_red))
                                .cornerRadius(8)
                            if errorMessage == "Please verify your email before signing in" {
                                Button(action: resendVerificationEmail) {
                                    Text("Resend Verification Email")
                                    .font(.custom("Inter-Regular", size: 18))
                                    .foregroundColor(Color(AppColors.moonstoneBlue))
                                }
                                .padding(.top, 10)
                            }
                        }
                                            
                        Button(action: loginUser) {
                            Text("LOG IN")
                                .padding(10)
                                .foregroundColor(.white)
                                .frame(width: geometry.size.width * 0.8)
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
                        .frame(width: geometry.size.width * 0.8)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        )
                        
                        Button(action: {
                            showEmailFieldForReset = true
                        }) {
                            Text("Forgot Password?")
                                .foregroundColor(Color(AppColors.moonstoneBlue))
                                .font(.custom("Inter-Medium", size: 15))
                        }
                        
                        VStack {
                            Text("New here?")
                                .font(.custom("Inter-Medium", size: 15))
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: SignUpView().navigationBarBackButtonHidden(true)) {
                                Text("JOIN THE VIBE")
                                    .font(.custom("Outfit-Medium", size: 15))
                                    .underline()
                                    .foregroundColor(Color(AppColors.moonstoneBlue))
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(40)
                    .frame(width: geometry.size.width * 0.8) // Adjust the width if needed
                    
                    Spacer()
                }
                .edgesIgnoringSafeArea(.vertical)
                .onChange(of: loginSuccess) { newValue in
                    if newValue {
                        navigateToSpotifyLogin = true
                    }
                }
                .fullScreenCover(isPresented: $navigateToSpotifyLogin) {
                    //SpotifyLogInView()
                    TaglineView()
                }
                .fullScreenCover(isPresented: $showEmailFieldForReset) {
                    NavigationView {
                        resetPasswordSheet
                            .navigationBarBackButtonHidden(true)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: {
                                        showEmailFieldForReset = false
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(Color.black)
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
    
    func loginUser() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                print("Error logging in:", error.localizedDescription)
                showError = true
                
                switch error.code {
                case AuthErrorCode.wrongPassword.rawValue:
                    errorMessage = "Incorrect Password"
                default:
                    errorMessage = "Log in failed"
                }
            } else if let authResult = authResult {
                if authResult.user.isEmailVerified {
                    DispatchQueue.main.async {
                        loginSuccess = true
                    }
                    Analytics.logEvent("log_in", parameters: [
                        AnalyticsParameterMethod: "email",
                    ])
                } else {
                    errorMessage = "Please verify your email before signing in"
                    showError = true
                }
            }
        }
    }
    
    func resendVerificationEmail() {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }

        currentUser.sendEmailVerification { error in
            if let error = error {
                print("Error resending verification email:", error.localizedDescription)
                // Handle the error, show an alert, etc.
            } else {
                print("Verification email resent successfully")
                // Update UI or show a success message
            }
        }
    }
    
    var resetPasswordSheet: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                Text("Forgot Password?")
                    .font(.custom("Outfit-Bold", size: 35))
                    .frame(width: geometry.size.width * 0.8)
                    .padding(.bottom, 20) 
                
                TextField("Email", text: $resetEmail)
                    .frame(width: geometry.size.width * 0.75)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                    .font(.custom("Inter-Light", size: 20))
                
                Button(action: {
                    resetPassword()
                }) {
                    Text("SEND RESET EMAIL")
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
                .padding()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: resetEmail) { error in
            if let error = error {
                print("Error sending password reset email:", error.localizedDescription)
            } else {
                print("Password reset email sent successfully")
                resetPasswordSuccess = true
            }
        }
    }
    
}
