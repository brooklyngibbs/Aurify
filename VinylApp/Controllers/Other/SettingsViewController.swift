import SwiftUI
import FirebaseStorage
import Firebase

struct SettingsViewController: View {
    @State private var notificationsEnabled = false
    @State private var darkModeEnabled = false
    @Binding var userProfileImage: UIImage?
    @State private var showImagePicker = false
    
    var userID: String
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    ProfileSectionView(profileImage: $userProfileImage, showImagePicker: $showImagePicker)
                }
                Section(header: Text("Payment")) {
                    // Payment related settings
                }
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .tint(Color.blue)
                }
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .tint(Color.blue)
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
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                AuthManager.shared.signOut { success in
                    if success {
                        // Navigate to LogInView after sign-out succeeds
                        // You can replace this with your own navigation logic
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
                        // Display an alert or any other appropriate action
                    }
                }
            }) {
                Text("Sign Out")
                    .foregroundColor(Color(AppColors.vampireBlack))
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
}


struct ProfileSectionView: View {
    @Binding var profileImage: UIImage?
    @Binding var showImagePicker: Bool
    
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
