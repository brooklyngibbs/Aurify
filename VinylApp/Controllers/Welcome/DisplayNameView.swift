import SwiftUI
import FirebaseAuth
import FirebaseFirestoreInternal
import FirebaseFirestore

struct DisplayNameView: View {
    @State private var name: String = ""
    @State private var shouldNavigateToProfilePicView = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color(AppColors.dark_moonstone), Color.white]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Firstly,")
                                .foregroundColor(.white)
                                .font(.custom("PlayfairDisplay-Bold", size: 60))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 10)
                            Text("What should we call you?")
                                .foregroundColor(.white)
                                .font(.custom("PlayfairDisplay-Bold", size: 40))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 10)
                        }
                        .frame(height: geometry.size.height / 3)


                        TextField("Name", text: $name)
                            .frame(width: geometry.size.width * 0.75)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(AppColors.gainsboro), lineWidth: 1))
                            .font(.custom("Inter-Light", size: 20))
                            .padding(.top, 40)
                        Spacer()

                        Button(action: {
                            setUserDisplayName(name: name)
                        }) {
                            Text("THAT'S ME")
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
                    }
                    .padding(.bottom, 20)
                    
                    NavigationLink(destination: ProfilePicView(), isActive: $shouldNavigateToProfilePicView) {
                        EmptyView()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func setUserDisplayName(name: String) {
        let db = Firestore.firestore()
        if let user = Auth.auth().currentUser {
            db.collection("users").document(user.uid).updateData(["name": name]) { error in
                if let error = error {
                    print("Error updating user data: \(error.localizedDescription)")
                } else {
                    print("User name updated successfully")
                    shouldNavigateToProfilePicView = true
                }
            }
        } else {
            // User is not authenticated
            print("User is not authenticated")
        }
    }

}
