import SwiftUI

struct SpotifyView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image("spotify_image")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UIScreen.main.bounds.height * 0.4)
            
            Text("Welcome to Soundtrak!")
                .font(.custom("Outfit-Bold", size: 30))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                // Handle Spotify Sign-In
                // Navigate to AuthView or handle Spotify authentication here
            }) {
                Text("Log in with Spotify!")
                    .font(.custom("Inter-Regular", size: 20))
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 200, height: 40)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 3)
            }
            
            Spacer()
        }
        .background(Color(red: 239.0/255.0, green: 235.0/255.0, blue: 226.0/255.0))
        .edgesIgnoringSafeArea(.all)
    }
}

struct SpotifyView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyView()
    }
}
