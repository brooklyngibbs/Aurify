import SwiftUI
import _StoreKit_SwiftUI
import FirebaseStorage
import Firebase
import StoreKit
import RevenueCat
import FirebaseAuth

struct SettingsViewController: View {
    @State private var notificationsEnabled = false
    @State private var darkModeEnabled = false
    @Binding var userProfileImage: UIImage?
    @State private var showImagePicker = false
    var userName: String
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    ProfileSectionView(profileImage: $userProfileImage, showImagePicker: $showImagePicker, userName: userName)
                }
                Section(header: Text("Subscription")) {
                    NavigationLink(destination: PaywallView()
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                    ) {
                        Text("Subscribe")
                    }
                }
                Section(header: Text("Terms and Conditions")) {
                    NavigationLink(destination: TermsAndConditionsView()
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                    ) {
                        Text("View Terms and Conditions")
                    }
                }

                Section(header: Text("Account")) {
                    AccountSectionView(userName: userName)
                }
                
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $userProfileImage, onSave: saveProfileImage, allowEditing: true)
            }
        }
    }

    func saveProfileImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("Failed to convert image to data.")
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let userID = Auth.auth().currentUser!.uid
        let profilePicsRef = storageRef.child("profilePics/\(userID)/profileImage.jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = profilePicsRef.putData(imageData, metadata: metadata) { metadata, error in
            guard let _ = metadata else {
                print("Error uploading profile image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            print("Profile image uploaded successfully.")
        }
    }
}

struct AccountSectionView: View {
    var userName: String
    @State private var isSignOutAlertPresented = false
    @State private var isDeleteAccountAlertPresented = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SignOutView(userName: userName, isPresented: $isSignOutAlertPresented)
                .onTapGesture {
                    isSignOutAlertPresented = true
                }
            
            DeleteAccountView(userName: userName, isPresented: $isDeleteAccountAlertPresented)
                .onTapGesture {
                    isDeleteAccountAlertPresented = true
                }
        }
    }
    
    func signOut() {
        AuthManager.shared.signOut { success in
            if success {
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let logInView = LogInView()
                        let hostingController = UIHostingController(rootView: logInView)
                        let navVC = UINavigationController(rootViewController: hostingController)
                        navVC.navigationBar.prefersLargeTitles = true
                        window.rootViewController = navVC
                        window.makeKeyAndVisible()
                        print("View transition completed")
                    }
                }
            } else {
                // Handle sign-out failure here
            }
        }
    }
    
    func deleteAccount(userName: String) {
        // Step 1: Delete User Playlists
        deletePlaylists { result in
            switch result {
            case .success:
                print("Successfully deleted user playlists")
                // Step 2: Delete User Data in Firestore
                deleteUserDataFromFirestore { result in
                    switch result {
                    case .success:
                        print("Successfully deleted user data from Firestore")
                        // Step 3: Delete User Account
                        deleteUserAccount()
                    case .failure(let error):
                        print("Failed to delete user data from Firestore: \(error.localizedDescription)")
                        // Handle failure if needed
                    }
                }
            case .failure(let error):
                print("Failed to delete user playlists: \(error.localizedDescription)")
                // Handle failure if needed
            }
        }
    }
    
    func deletePlaylists(completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure that the user is currently authenticated
        guard let user = Auth.auth().currentUser else {
            print("No user is currently signed in.")
            // Handle not authenticated case if needed
            return
        }

        let userID = user.uid
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        let playlistsRef = userRef.collection("playlists")

        playlistsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                for document in snapshot?.documents ?? [] {
                    let playlistRef = playlistsRef.document(document.documentID)

                    // Check if cover_image_url field exists in the document
                    if let coverImageURL = document["cover_image_url"] as? String {
                        // Construct path to the image in Firebase Storage
                        let storageReference = Storage.storage().reference(forURL: coverImageURL)

                        // Delete the image from Firebase Storage
                        storageReference.delete { error in
                            if let error = error {
                                print("Error deleting image: \(error.localizedDescription)")
                                // Handle failure if needed
                            } else {
                                print("Image deleted successfully")
                            }
                        }
                    }

                    // mark playlist as deleted 
                    playlistRef.updateData(["deleted": true])
                }
                completion(.success(()))
            }
        }
    }

    
    func deleteUserDataFromFirestore(completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure that the user is currently authenticated
        guard let user = Auth.auth().currentUser else {
            print("No user is currently signed in.")
            // Handle not authenticated case if needed
            return
        }

        let userID = user.uid
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)

        userRef.delete { error in
            if let error = error {
                print("Error deleting user data from Firestore: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("User data deleted successfully from Firestore")
                let storage = Storage.storage()
                let storageRef = storage.reference()
                let profilePicsRef = storageRef.child("profilePics/\(userID)/profileImage.jpg")

                profilePicsRef.delete { error in
                    if let error = error {
                        print("Error deleting profile picture: \(error.localizedDescription)")
                        // Handle failure if needed
                    } else {
                        print("Profile picture deleted successfully")
                    }
                }
                completion(.success(()))
            }
        }
    }

    
    func deleteUserAccount() {
        print("deleteUserAccount function started")
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "expirationDate")
        UserDefaults.standard.removeObject(forKey: "expires_in")
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "SubscriptionType")
        print("user defaults removed")
        
        // Ensure that the user is currently authenticated
        guard let user = Auth.auth().currentUser else {
            print("User is not authenticated")
            // Handle not authenticated case if needed
            return
        }
        
        let userID = user.uid
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        userRef.delete { error in
            if let error = error {
                print("Error deleting user data from Firestore: \(error.localizedDescription)")
                // Handle failure if needed
            } else {
                print("User data deleted successfully from Firestore")
                let storage = Storage.storage()
                let storageRef = storage.reference()
                let profilePicsRef = storageRef.child("profilePics/\(userID)/profileImage.jpg")
                
                profilePicsRef.delete { error in
                    if let error = error {
                        print("Error deleting profile picture: \(error.localizedDescription)")
                        // Handle failure if needed
                    } else {
                        print("Profile picture deleted successfully")
                    }
                }
                
                // Finally, delete the user's account
                user.delete { error in
                    if let error = error {
                        print("Error deleting user account: \(error.localizedDescription)")
                        // Handle failure if needed
                    } else {
                        print("User account deleted successfully")
                        // Perform the view transition here
                        DispatchQueue.main.async {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                let logInView = LogInView()
                                let hostingController = UIHostingController(rootView: logInView)
                                let navVC = UINavigationController(rootViewController: hostingController)
                                navVC.navigationBar.prefersLargeTitles = true
                                window.rootViewController = navVC
                                window.makeKeyAndVisible()
                                print("View transition completed")
                            }
                        }
                    }
                }
            }
        }
        
        print("deleteUserAccount function completed")
    }
}



struct ProfileSectionView: View {
    @Binding var profileImage: UIImage?
    @Binding var showImagePicker: Bool
    var userName: String
    @State private var subscriptionStatus: SubscriptionManager.SubscriptionType = .none
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .resizable()
                        .foregroundColor(Color.black)
                        .frame(width: 27, height: 27)
                        .padding(5)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                        )
                }
                .clipShape(Circle())
                .offset(x: 4, y: 4)
            } else {
                Circle()
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }
        }
        .onAppear {
            // Fetch subscription type asynchronously
            Task {
                do {
                    let customerInfo = try await Purchases.shared.customerInfo()
                    let entitlementId = "fullAccess"
                    
                    if customerInfo.entitlements.all[entitlementId]?.isActive == true {
                        // User is "premium"
                        self.subscriptionStatus = .fullAccess
                    } else {
                        self.subscriptionStatus = .none
                    }
                } catch {
                    print("Error fetching subscription type: \(error.localizedDescription)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .cornerRadius(10)
        Text("Name: \(userName)")
        Text("Subscription: \(subscriptionStatus == .fullAccess ? "Full Access" : "None")")
    }
}

struct TermsAndConditionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("""
                Terms and Conditions for Aurify

                Last Updated: January 2024

                Welcome to Aurify! These terms and conditions outline the rules and regulations for the use of the Aurify mobile application, available on iOS and Android platforms, created by Brooklyn Gibbs.

                By accessing Aurify, we assume you accept these terms and conditions. Do not continue to use Aurify if you do not agree to take all of the terms and conditions stated on this page.

                1. Acceptance of Terms

                By using Aurify, you agree to comply with these terms and conditions, our Privacy Policy, and any additional terms and conditions that may apply to specific features or services offered within the app.

                2. Use of Aurify

                Aurify is designed to create playlists on Spotify based on images stored in your camera roll.
                Users must have a valid Spotify account to use the playlist creation feature within Aurify.
                The app utilizes images from your camera roll solely for the purpose of generating Spotify playlists and does not store or share these images without explicit consent.

                3. User Content

                You retain ownership of any content uploaded or created by you within Aurify.
                By using Aurify, you grant us a non-exclusive, transferable, sub-licensable, royalty-free, worldwide license to use any uploaded content for the sole purpose of providing and improving the app’s services.

                4. Privacy

                We take user privacy seriously. Please refer to our Privacy Policy for information on how we collect, use, and disclose information.

                5. Account Termination

                We reserve the right to suspend or terminate your access to Aurify at our discretion if we believe you have violated these terms and conditions or engaged in improper use of the app.

                6. Disclaimer

                                Aurify is provided "as is" and "as available" without warranties of any kind, either expressed or implied.
                We do not guarantee that the app will always be available, uninterrupted, secure, or error-free.

                7. Limitation of Liability

                To the extent permitted by law, Aurify, its affiliates, or employees shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from your access to or use of Aurify.

                8. Changes to Terms and Conditions

                We reserve the right to modify or replace these terms and conditions at any time. Your continued use of Aurify after any changes indicate your acceptance of those changes.

                9. Contact Information

                For questions or concerns regarding these terms and conditions, please contact us at contactus@aurifyapp.com.
                By using Aurify, you acknowledge that you have read and understood these terms and conditions and agree to be bound by them.
                """)
                .padding()
            }
        }
        .navigationBarTitle("Terms and Conditions", displayMode: .inline)
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onSave: (UIImage) -> Void
    var allowEditing: Bool
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        var onSave: (UIImage) -> Void
        
        init(parent: ImagePicker, onSave: @escaping (UIImage) -> Void) {
            self.parent = parent
            self.onSave = onSave
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.editedImage] as? UIImage { // Use .editedImage to get the cropped image if editing is allowed
                onSave(uiImage)
                parent.image = uiImage
            } else if let uiImage = info[.originalImage] as? UIImage {
                onSave(uiImage)
                parent.image = uiImage
            }
            picker.dismiss(animated: true, completion: nil)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, onSave: onSave) // Pass onSave closure
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = allowEditing
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update
    }
}

struct SignOutView: View {
    var userName: String
    @Binding var isPresented: Bool
    @State private var showAlert: Bool = false

    var body: some View {
        VStack {
            Text("Sign Out")
                .onTapGesture {
                    showAlert = true
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Sign Out"),
                        message: Text("Are you sure you want to sign out?"),
                        primaryButton: .default(Text("Yes")) {
                            isPresented = false
                            AccountSectionView(userName: userName).signOut()
                        },
                        secondaryButton: .cancel(Text("No"))
                    )
                }
        }
    }
}

struct DeleteAccountView: View {
    var userName: String
    @Binding var isPresented: Bool
    @State private var showAlert: Bool = false
    @State private var isReauthViewPresented: Bool = false

    var body: some View {
        VStack {
            Text("Delete Account")
                .foregroundColor(Color(AppColors.venetian_red))
                .onTapGesture {
                    showAlert = true
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Delete Account"),
                        message: Text("This action cannot be undone"),
                        primaryButton: .default(Text("Delete")) {
                            isReauthViewPresented = true
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
                .fullScreenCover(isPresented: $isReauthViewPresented) {
                    ReauthView(userName: userName, isReauthSuccessful: $isReauthViewPresented)
                }
        }
    }
}

struct ReauthView: View {
    var userName: String
    @Binding var isReauthSuccessful: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var reauthError: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Delete Account")
                    .font(.custom("Outfit-Bold", size: 35))
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.custom("Inter-Light", size: 20))
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.custom("Inter-Light", size: 20))
                    .padding()
                
                Button(action: {
                    reauthenticate()
                }) {
                    Text("Confirm")
                        .foregroundColor(Color.white)
                        .padding()
                        .font(.custom("Inter-Regular", size: 18))
                        .background(Color(AppColors.moonstoneBlue))
                        .cornerRadius(8)
                }
                
                // Display an error message if reauthentication fails
                if let error = reauthError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationBarItems(leading: Button("Cancel") {
                // Handle back action, for example, by dismissing the sheet or navigating back
                isReauthSuccessful = false
            })
            .foregroundColor(Color(AppColors.vampireBlack))
        }
    }
    
    func reauthenticate() {
        // Get the current user
        guard let user = Auth.auth().currentUser else {
            print("No user is currently signed in.")
            return
        }
        
        // Create credentials using the provided email and password
        let credentials = EmailAuthProvider.credential(withEmail: email, password: password)
        
        // Reauthenticate the user
        user.reauthenticate(with: credentials) { authResult, error in
            if let error = error {
                // Reauthentication failed
                print("Reauthentication failed: \(error.localizedDescription)")
                reauthError = "Reauthentication failed. Please check your email and password."
            } else {
                // Reauthentication successful
                print("Reauthentication successful")
                AccountSectionView(userName: userName).deleteAccount(userName: userName)
            }
        }
    }
}
