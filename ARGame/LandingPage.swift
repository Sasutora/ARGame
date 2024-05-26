//
//  LandingPage.swift
//  ARGame
//
//  Created by Rama Eka Hartono on 21/05/24.
//

import SwiftUI

struct LandingPage: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Background Image
                Image("fruit")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                // Overlay content
                VStack {
                    Spacer()
                    
                    Text("Welcome to Fruit AR!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                        .padding(.top, 100)
                    
                    Spacer()
                    
                    NavigationLink(destination: ContentView()) {
                        Text("Get Started")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]), startPoint: .top, endPoint: .bottom)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                            )
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.cornerRadius(15))
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                    }
                    .padding(.bottom, 100)
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: 600) // Limit max width for better layout on larger screens
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // For better compatibility on iPad
    }
}

struct LandingPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LandingPage()
                .previewDevice("iPhone 13 Pro Max")
            
            LandingPage()
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
        }
    }
}
