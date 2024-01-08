import SwiftUI
import FirebaseStorage
import Firebase

struct SettingsViewController: View {
    @State private var notificationsEnabled = false
    @State private var darkModeEnabled = false
    @Binding var userProfileImage: UIImage?
    @State private var showImagePicker = false
    var userName: String
    
    var userID: String
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    ProfileSectionView(profileImage: $userProfileImage, showImagePicker: $showImagePicker, userName: userName)
                }
                Section(header: Text("Payment")) {
                    // Payment related settings
                }
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .tint(Color.blue)
                }
                Section(header: Text("Terms and Conditions")) {
                    NavigationLink(destination: TermsAndConditionsView()) {
                        Text("View Terms and Conditions")
                    }
                }
                Section(header: Text("Account")) {
                    AccountSectionView()
                }
                
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $userProfileImage, onSave: saveProfileImage)
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
    
    @State private var showingSignOutAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showingSignOutAlert = true
            }) {
                Text("Sign Out")
                    .foregroundColor(Color(AppColors.vampireBlack))
            }
            .alert(isPresented: $showingSignOutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .default(Text("Yes")) {
                        signOut()
                    },
                    secondaryButton: .cancel(Text("No"))
                )
            }
            .padding(.bottom, 15)
            
            Button(action: {
                // action for delete account
            }) {
                Text("Delete Account")
                    .foregroundColor(Color(AppColors.venetian_red))
            }
        }
    }
    func signOut() {
        AuthManager.shared.signOut { success in
            if success {
                if let window = UIApplication.shared.windows.first {
                    let logInView = LogInView()
                    let hostingController = UIHostingController(rootView: logInView)
                    let navVC = UINavigationController(rootViewController: hostingController)
                    navVC.navigationBar.prefersLargeTitles = true
                    window.rootViewController = navVC
                    window.makeKeyAndVisible()
                }
            } else {
                // Handle sign-out failure here
            }
        }
    }
}


struct ProfileSectionView: View {
    @Binding var profileImage: UIImage?
    @Binding var showImagePicker: Bool
    var userName: String
    
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
                .offset(x: 4, y: 4) //adjust position in profile circle
            } else {
                Circle()
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .cornerRadius(10)
        Text("Name: \(userName ?? "Unavailable")")
    }
}

struct TermsAndConditionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("""
                Terms and Conditions for Soundtrak

                Last Updated: January 20223

                Welcome to Soundtrak! These terms and conditions outline the rules and regulations for the use of the Soundtrak mobile application, available on iOS and Android platforms, created by Brooklyn Gibbs.

                By accessing Soundtrak, we assume you accept these terms and conditions. Do not continue to use Soundtrak if you do not agree to take all of the terms and conditions stated on this page.

                1. Acceptance of Terms

                By using Soundtrak, you agree to comply with these terms and conditions, our Privacy Policy, and any additional terms and conditions that may apply to specific features or services offered within the app.

                2. Use of Soundtrak

                Soundtrak is designed to create playlists on Spotify based on images stored in your camera roll.
                Users must have a valid Spotify account to use the playlist creation feature within Soundtrak.
                The app utilizes images from your camera roll solely for the purpose of generating Spotify playlists and does not store or share these images without explicit consent.

                3. User Content

                You retain ownership of any content uploaded or created by you within Soundtrak.
                By using Soundtrak, you grant us a non-exclusive, transferable, sub-licensable, royalty-free, worldwide license to use any uploaded content for the sole purpose of providing and improving the app’s services.

                4. Privacy

                We take user privacy seriously. Please refer to our Privacy Policy for information on how we collect, use, and disclose information.

                5. Account Termination

                We reserve the right to suspend or terminate your access to Soundtrak at our discretion if we believe you have violated these terms and conditions or engaged in improper use of the app.

                6. Disclaimer

                Soundtrak is provided "as is" and "as available" without warranties of any kind, either expressed or implied.
                We do not guarantee that the app will always be available, uninterrupted, secure, or error-free.

                7. Limitation of Liability

                To the extent permitted by law, Soundtrak, its affiliates, or employees shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from your access to or use of Soundtrak.

                8. Changes to Terms and Conditions

                We reserve the right to modify or replace these terms and conditions at any time. Your continued use of Soundtrak after any changes indicate your acceptance of those changes.

                9. Contact Information

                For questions or concerns regarding these terms and conditions, please contact us at brooklyngibbs22@gmail.com.
                By using Soundtrak, you acknowledge that you have read and understood these terms and conditions and agree to be bound by them.
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
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        var onSave: (UIImage) -> Void
        
        init(parent: ImagePicker, onSave: @escaping (UIImage) -> Void) {
            self.parent = parent
            self.onSave = onSave
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
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
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update
    }
}
