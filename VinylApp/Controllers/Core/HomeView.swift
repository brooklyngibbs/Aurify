import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                CustomTitleView() 
                Text("Your Content Here")
                    .padding()
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

