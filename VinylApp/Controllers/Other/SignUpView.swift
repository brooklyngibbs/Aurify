import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var userCreated: Bool = false
    @State private var navigateToLogin: Bool = false

    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @State private var showSuccess: Bool = false
    @State private var successMessage: String = ""
    
    @State private var firestoreEmails: [String] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 20) {
                        Text("Sign Up")
                            .font(.custom("Outfit-Bold", size: 35))
                        
                        TextField("Email", text: $email)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                            .font(.custom("Inter-Light", size: 20))
                        
                        SecureField("Password", text: $password)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                            .font(.custom("Inter-Light", size: 20))
                            .padding(.bottom, 10)
                        
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .font(.custom("Inter-Medium", size: 15))
                                .padding(8)
                                .background(Color(AppColors.venetian_red))
                                .cornerRadius(8)
                        }
                        
                        Button(action: signUp) {
                            Text("Sign Up")
                                .padding(10)
                                .foregroundColor(.white)
                                .background(Color(AppColors.moonstoneBlue))
                                .font(.custom("Inter-Regular", size: 18))
                                .cornerRadius(8)
                        }
                        
                        HStack {
                            Text("Already have an account?")
                                .font(.custom("Inter-Light", size: 15))
                            
                            NavigationLink(destination: LogInView().navigationBarBackButtonHidden(true)) {
                                Text("Log In")
                                    .font(.custom("Log in", size: 15))
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
                LogInView()
            }
        }
        .onAppear {
            fetchFirestoreEmails()
        }
    }
    
    func fetchFirestoreEmails() {
        let db = Firestore.firestore()
        
        db.collection("users").getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching documents: \(error)")
            } else {
                self.firestoreEmails = querySnapshot?.documents.compactMap { $0["email"] as? String } ?? []
            }
        }
    }
    
    func createUser(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            completion(authResult, error)
        }
    }
    
    func signUp() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Check if the email is in the Firestore array
        guard firestoreEmails.contains(email) else {
            errorMessage = "Development mode user limit reached. Unable to create more users."
            showError = true
            return
        }

        // Create the user
        createUser(email: email, password: password) { authResult, error in
            if let error = error as NSError? {
                switch error.code {
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    errorMessage = "Email is already in use"
                    showError = true
                case AuthErrorCode.weakPassword.rawValue:
                    errorMessage = "Password should be at least 6 characters"
                    showError = true
                // Add more cases for other error codes if needed
                default:
                    errorMessage = "An error occurred"
                    showError = true
                }
            } else if let authResult = authResult {
                print("User created successfully")
                sendEmailVerification(for: authResult.user) // Call to send email verification
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
                // You may want to inform the user to check their email for verification
            }
        }
    }
}
