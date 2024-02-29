import Foundation
import SwiftUI
import Firebase

struct TaglineView: View {
    
    @State private var presentNext = false
    @State private var textOffset1: CGFloat = -UIScreen.main.bounds.width
    @State private var textOffset2: CGFloat = -UIScreen.main.bounds.width
    @State private var textOffset3: CGFloat = -UIScreen.main.bounds.width
    @State private var textOffset4: CGFloat = -UIScreen.main.bounds.width
    @State private var buttonOpacity: Double = 0
    @State private var email: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(AppColors.dark_moonstone), Color.white]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading) {
                    Spacer()
                    Text("Capture")
                        .foregroundColor(.white)
                        .font(.custom("PlayfairDisplay-Bold", size: 60))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                        .offset(x: textOffset1)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 0.8).delay(0.5)) {
                                textOffset1 = 10
                            }
                        }
                    Text("Moments.")
                        .foregroundColor(.white)
                        .font(.custom("PlayfairDisplay-Italic", size: 60))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                        .offset(x: textOffset2)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 0.8).delay(0.7)) {
                                textOffset2 = 10
                            }
                        }
                        .padding(.bottom)
                    Text("Curate")
                        .foregroundColor(.white)
                        .padding(.top)
                        .font(.custom("PlayfairDisplay-Bold", size: 60))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(x: textOffset3)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 0.8).delay(0.9)) {
                                textOffset3 = 10
                            }
                        }
                        .padding(.leading, 10)
                    Text("Playlists.")
                        .foregroundColor(.white)
                        .font(.custom("PlayfairDisplay-Italic", size: 60))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(x: textOffset4)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 0.8).delay(1.1)) {
                                textOffset4 = 10
                            }
                            withAnimation(Animation.easeInOut(duration: 0.5).delay(1.3)) {
                                buttonOpacity = 1
                            }
                        }
                        .padding(.leading, 10)
                    Spacer()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack {
                    Spacer()
                    Button(action: {
                        presentNext = true
                    }) {
                        Text("LET'S GET STARTED")
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
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $presentNext) {
                if email == "aurifyapp@gmail.com" {
                    SpotifyLogInView()
                } else {
                    TakeMeToAurifyView()
                }
            }
            .onAppear {
                email = Auth.auth().currentUser?.email
                print("Signed in with email: \(email ?? "Unknown")")
            }
        }
    }
}
