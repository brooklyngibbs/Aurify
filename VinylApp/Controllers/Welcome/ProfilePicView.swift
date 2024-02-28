import SwiftUI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestoreInternal
import FirebaseFirestore
import UIKit

struct ProfilePicView: View {

    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isProfilePicSaved = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color(AppColors.dark_moonstone), Color.white]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Hey Brooklyn,")
                                .foregroundColor(.white)
                                .font(.custom("PlayfairDisplay-Bold", size: 50))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 10)
                            Text("set a profile picture.")
                                .foregroundColor(.white)
                                .font(.custom("PlayfairDisplay-Bold", size: 30))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 10)
                        }
                        .frame(height: geometry.size.height / 3)

                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 200, height: 200)
                                .shadow(radius: 5)

                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 190, height: 190)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 190, height: 190)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, 40)
                        .onTapGesture {
                            isImagePickerPresented = true
                        }

                        Spacer()

                        Button(action: {
                            if let image = selectedImage {
                                saveProfileImage(image)
                            } else {
                                print("No image selected")
                            }
                        }) {
                            Text("LOOKS GOOD")
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
                        
                        Button(action: {
                            defaultProfilePic()
                        }) {
                            Text("SKIP FOR NOW")
                                .padding(10)
                                .foregroundColor(Color(AppColors.moonstoneBlue))
                                .frame(width: UIScreen.main.bounds.width * 0.8)
                                .font(.custom("Outfit-Medium", size: 18))
                                .cornerRadius(20)
                                .kerning(1.8)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage, onSave: { image in
                    self.selectedImage = image
                    saveProfileImage(image)
                }, allowEditing: true)
            }
        }
        .navigationBarBackButtonHidden(true)
        NavigationLink(destination: WelcomeSignInView(), isActive: $isProfilePicSaved) {
            EmptyView()
        }
        .hidden()
        .navigationBarBackButtonHidden(true)
    }
    
    func saveProfileImage(_ image: UIImage) {
        guard let user = Auth.auth().currentUser else {
            print("User is not authenticated")
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }

        let storageRef = Storage.storage().reference().child("profilePics/\(user.uid)/profilePic.jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
            } else {
                print("Image uploaded successfully")
                isProfilePicSaved = true
            }
        }
    }
    
    func defaultProfilePic() {
        guard let user = Auth.auth().currentUser else {
            print("User is not authenticated")
            return
        }

        let tempProfilePicsRef = Storage.storage().reference().child("profilePics/tempProfilePics")

        // List all items in the tempProfilePics bucket
        tempProfilePicsRef.listAll { (result, error) in
            if let error = error {
                print("Error listing default profile pictures: \(error.localizedDescription)")
                return
            }

            // Choose a random default profile picture
            let randomIndex = Int.random(in: 0..<result!.items.count)
            let randomProfilePicRef = result!.items[randomIndex]

            // Download the random profile picture
            randomProfilePicRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading random profile picture: \(error.localizedDescription)")
                    return
                }

                guard let imageData = data else {
                    print("Failed to get random profile picture data")
                    return
                }

                // Save the random profile picture to the user's profilePics/user_id/profilePic.jpg location
                let profilePicRef = Storage.storage().reference().child("profilePics/\(user.uid)/profilePic.jpg")
                profilePicRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        print("Error uploading random profile picture: \(error.localizedDescription)")
                        return
                    }
                    print("Random profile picture uploaded successfully")
                    isProfilePicSaved = true
                }
            }
        }
    }
}

