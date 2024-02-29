import SwiftUI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestoreInternal
import FirebaseFirestore
import UIKit

struct WelcomeSignInView: View {
    
    @State private var textOffset1: CGFloat = -UIScreen.main.bounds.width
    @State private var textOffset2: CGFloat = -UIScreen.main.bounds.width
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color(AppColors.dark_moonstone), Color.white]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Great!")
                                .foregroundColor(.white)
                                .font(.custom("PlayfairDisplay-Bold", size: 50))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: textOffset1)
                                .onAppear {
                                    withAnimation(Animation.easeOut(duration: 0.8).delay(0.5)) {
                                        textOffset1 = 10
                                    }
                                }
                                .padding(.leading, 10)
                            Text("Now, let's sign you in.")
                                .foregroundColor(.white)
                                .font(.custom("PlayfairDisplay-Bold", size: 30))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: textOffset2)
                                .onAppear {
                                    withAnimation(Animation.easeOut(duration: 0.8).delay(0.7)) {
                                        textOffset2 = 10
                                    }
                                    withAnimation(Animation.easeInOut(duration: 0.5).delay(0.9)) {
                                        buttonOpacity = 1
                                    }
                                }
                                .padding(.leading, 10)
                        }
                        .frame(height: geometry.size.height / 3)
                        
                        Spacer()
                        
                        NavigationLink(destination: LogInView().navigationBarBackButtonHidden(true)) {
                            Text("LOG IN")
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
                        .opacity(buttonOpacity)
                        .navigationBarBackButtonHidden(true)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

