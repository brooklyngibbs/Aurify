import SwiftUI
import FirebaseAuth

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
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("Log In")
                            .font(.custom("Outfit-Bold", size: 35))
                            .frame(width: geometry.size.width * 0.8) // Adjust the width if needed
                        
                        TextField("Email", text: $email)
                            .frame(width: geometry.size.width * 0.75)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                            .font(.custom("Inter-Light", size: 20))
                        
                        SecureField("Password", text: $password)
                            .frame(width: geometry.size.width * 0.75)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                            .font(.custom("Inter-Light", size: 20))
                        
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .font(.custom("Inter-Medium", size: 15))
                                .frame(width: geometry.size.width * 0.75)
                                .padding(8)
                                .background(Color(AppColors.venetian_red))
                                .cornerRadius(8)
                        }
                        
                        Button(action: loginUser) {
                            Text("Log In")
                                .padding(10)
                                .foregroundColor(.white)
                                .background(Color(AppColors.moonstoneBlue))
                                .font(.custom("Inter-Regular", size: 18))
                                .cornerRadius(8)
                        }
                        .frame(width: geometry.size.width * 0.8)
                        
                        Button(action: {
                            showEmailFieldForReset = true
                        }) {
                            Text("Forgot Password?")
                                .foregroundColor(Color(AppColors.moonstoneBlue))
                                .font(.custom("Inter-Light", size: 15))
                        }
                        
                        HStack {
                            Text("Don't have an account?")
                                .font(.custom("Inter-Light", size: 15))
                            
                            NavigationLink(destination: SignUpView().navigationBarBackButtonHidden(true)) {
                                Text("Sign Up")
                                    .font(.custom("Inter-Light", size: 15))
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
                    SpotifyLogInView()
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
                    loginSuccess = true
                } else {
                    errorMessage = "Please verify your email before signing in"
                    showError = true
                }
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
                    .padding(.bottom, 20) // Adjust the spacing between elements if needed
                
                TextField("Email", text: $resetEmail)
                    .frame(width: geometry.size.width * 0.75)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                    .font(.custom("Inter-Light", size: 20))
                
                Button(action: {
                    resetPassword()
                }) {
                    Text("Send Reset Email")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(AppColors.moonstoneBlue))
                        .cornerRadius(8)
                        .font(.custom("Inter-Light", size: 15))
                }
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
