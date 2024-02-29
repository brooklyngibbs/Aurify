import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth
import Firebase
import FirebaseAnalytics

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var userCreated: Bool = false
    @State private var navigateToLogin: Bool = false

    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @State private var showSuccess: Bool = false
    @State private var successMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 20) {
                        Text("Aurify")
                            .font(.custom("Outfit-Bold", size: 40))
                            .padding(.bottom)
                        
                        TextField("Email", text: $email)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                            .font(.custom("Inter-Light", size: 20))
                        
                        SecureField("Password", text: $password)
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
                                .padding(8)
                                .background(Color(AppColors.venetian_red))
                                .cornerRadius(8)
                        }
                        
                        Button(action: signUp) {
                            Text("SIGN UP")
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
                        
                        VStack {
                            Text("Already have an account?")
                                .font(.custom("Inter-Medium", size: 15))
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: LogInView().navigationBarBackButtonHidden(true)) {
                                Text("LOG IN")
                                    .font(.custom("Outfit-Medium", size: 15))
                                    .underline()
                                    .foregroundColor(Color(AppColors.moonstoneBlue))
                            }
                            
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(40)
                    
                    Spacer()
                    
                    NavigationLink(
                        destination: LogInView().navigationBarBackButtonHidden(true),
                        isActive: $navigateToLogin,
                        label: { EmptyView() }
                    )
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .disabled(true)
                }
            }
            .padding(.horizontal, 20)
            .edgesIgnoringSafeArea(.all)
            .fullScreenCover(isPresented: $userCreated) {
                //LogInView()
                DisplayNameView()
            }
        }
    }
    
    func createUser(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                completion(nil, error)
                return
            }

            guard let user = authResult?.user else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                completion(nil, error)
                return
            }

            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "email": email
            ]

            print("Attempting to save email: \(email)")

            // Set the user data in Firestore under 'users/userId'
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    print("Error setting user data: \(error.localizedDescription)")
                    completion(nil, error)
                } else {
                    print("User data set successfully")
                    completion(authResult, nil)
                }
            }

        }
    }

    
    func signUp() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        createUser(email: email, password: password) { authResult, error in
            if let error = error as NSError? {
                switch error.code {
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    errorMessage = "Email is already in use"
                    showError = true
                case AuthErrorCode.weakPassword.rawValue:
                    errorMessage = "Password should be at least 6 characters"
                    showError = true
                default:
                    errorMessage = "An error occurred"
                    showError = true
                }
            } else if let authResult = authResult {
                print("User created successfully")
                Analytics.logEvent("sign_up", parameters: nil)
                sendEmailVerification(for: authResult.user)
                self.userCreated = true
            }
        }
    }


    
    func sendEmailVerification(for user: FirebaseAuth.User) {
        user.sendEmailVerification { error in
            if let error = error {
                print("Error sending verification email:", error.localizedDescription)
            } else {
                print("Verification email sent successfully")
                //inform user somehow 
            }
        }
    }
}
