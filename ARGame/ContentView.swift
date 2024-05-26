import SwiftUI
import RealityKit
import ARKit
import AVFoundation

struct ContentView: View {
    @State private var showOverlay = true
    @State private var showWinOverlay = false
    @State private var showLoseOverlay = false
    @State private var restartGame = false
    @State private var hearts = 3 // Initial hearts count

    var body: some View {
        ZStack {
            ARViewContainer(showOverlay: $showOverlay, showWinOverlay: $showWinOverlay, showLoseOverlay: $showLoseOverlay, restartGame: $restartGame, hearts: $hearts)
                .edgesIgnoringSafeArea(.all)
                .navigationBarBackButtonHidden(true)

            if showOverlay {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Text("🔍")
                                .font(.system(size: 50))
                            Text("Direct your camera to a flat surface")
                                .font(.title2)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .transition(.move(edge: .bottom))
                        Spacer()
                    }
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showOverlay = false
                    }
                }
            }

            if showWinOverlay {
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("🎉")
                            .font(.system(size: 50))
                        Text("You Win!")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
//                        Button(action: {
//                            restartGame = true
//                            hearts = 3 // Reset hearts when restarting the game
//                            showWinOverlay = false // Hide win overlay
//                        }) {
//                            Text("Restart Game")
//                                .font(.title2)
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .transition(.scale)
                    Spacer()
                }
            }

            if showLoseOverlay {
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("😔")
                            .font(.system(size: 50))
                        Text("You Lose!")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
//                        Button(action: {
//                            restartGame = true
//                            hearts = 3 // Reset hearts when restarting the game
//                            showLoseOverlay = false // Hide lose overlay
//                        }) {
//                            Text("Restart Game")
//                                .font(.title2)
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .transition(.scale)
                    Spacer()
                }
            }

            if !showOverlay {
                VStack {
                                   HStack {
                                       Spacer()
                                       ForEach(0..<max(0, hearts), id: \.self) { _ in
                                           Image(systemName: "heart.fill")
                                               .foregroundColor(.red)
                                               .font(.largeTitle) // Adjust the size of the hearts if necessary
                                       }
                                       Spacer()
                                   }
                                   .padding()
                                   Spacer()
                               }            }
        }
    }
}
