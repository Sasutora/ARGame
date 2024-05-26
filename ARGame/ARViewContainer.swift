import SwiftUI
import RealityKit
import ARKit
import AVFoundation
struct ARViewContainer: UIViewRepresentable {
    @Binding var showOverlay: Bool
    @Binding var showWinOverlay: Bool
    @Binding var showLoseOverlay: Bool
    @Binding var restartGame: Bool
    @Binding var hearts: Int
    
    func makeCoordinator() -> Coordinator {
        Coordinator(showOverlay: $showOverlay, showWinOverlay: $showWinOverlay, showLoseOverlay: $showLoseOverlay, restartGame: $restartGame, hearts: $hearts)
            }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        context.coordinator.arView = arView

        // Configure ARView
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if restartGame {
            context.coordinator.resetGame()
            restartGame = false
        }
        context.coordinator.arView = uiView // Sisipkan koordinator yang baru
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var audioPlayer: AVAudioPlayer?
        var arView: ARView?
        var cards: [Entity] = []
        var isFlipped: [Bool] = Array(repeating: false, count: 12)
        var matched: [Bool] = Array(repeating: false, count: 12)
        var firstIndex = -1
        var secondIndex = -1
        var isChecking = false
        var showOverlay: Binding<Bool>
        var showWinOverlay: Binding<Bool>
        var showLoseOverlay: Binding<Bool>
        var restartGame: Binding<Bool>
        var hearts: Binding<Int> // Binding for hearts

              init(showOverlay: Binding<Bool>, showWinOverlay: Binding<Bool>, showLoseOverlay: Binding<Bool>, restartGame: Binding<Bool>, hearts: Binding<Int>) {
                  self.showOverlay = showOverlay
                  self.showWinOverlay = showWinOverlay
                  self.showLoseOverlay = showLoseOverlay
                  self.restartGame = restartGame
                  self.hearts = hearts
              }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = sender.location(in: arView)
            if let entity = arView.entity(at: location) {
                for (index, card) in cards.enumerated() {
                    if card.children.contains(entity) {
                        if matched[index] || isFlipped[index] || isChecking {
                            return
                        }
                        flipCard(at: index)
                        if firstIndex == -1 {
                            playSound()
                            firstIndex = index
                        } else if secondIndex == -1 {
                            playSound()
                            secondIndex = index
                            isChecking = true
                            checkMatch()
                        }
                        break
                    }
                }
            }
        }

        func flipCard(at index: Int) {
            guard index < cards.count else { return }
            let cardEntity = cards[index]
            guard let card = cardEntity.children.first(where: { $0.name == "card" }) as? ModelEntity,
                  let asset = cardEntity.children.first(where: { $0.name.hasSuffix(".usdz") }) as? ModelEntity else {
                print("Error: Card or asset not found for index \(index)")
                return
            }
            var flipTransform = card.transform
            let animationDuration: TimeInterval = 0.5

            if isFlipped[index] {
                if firstIndex != -1 && secondIndex != -1 {
                    flipTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration / 2) {
                        asset.isEnabled = false
                    }
                    isFlipped[index] = false
                } else {
                                   // If the card is already flipped, flip it back
                                   flipTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
                                   asset.isEnabled = false
                                   isFlipped[index] = false
                               }
                           } else {
                               // Flip the card
                               flipTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                               asset.isEnabled = true
                               isFlipped[index] = true
                           }

                           // Apply the flip animation
                           card.move(to: flipTransform, relativeTo: card.parent, duration: animationDuration)
                       }

                       func checkMatch() {
                           guard firstIndex != -1, secondIndex != -1 else { return }
                           let firstCard = cards[firstIndex]
                           let secondCard = cards[secondIndex]
                           guard let firstAsset = firstCard.children.first(where: { $0.name.hasSuffix(".usdz") }) as? ModelEntity,
                                 let secondAsset = secondCard.children.first(where: { $0.name.hasSuffix(".usdz") }) as? ModelEntity else {
                               print("Error: Asset not found for firstIndex or secondIndex")
                               return
                           }
                           
                           if firstAsset.name == secondAsset.name {
                               // If cards match, mark them as matched
                               matched[firstIndex] = true
                               matched[secondIndex] = true
                               firstIndex = -1
                               secondIndex = -1
                               isChecking = false
                               checkWinCondition()
                           } else {
                               // If cards don't match, decrease the hearts count
                               DispatchQueue.main.async {
                                    self.hearts.wrappedValue -= 1
                               }
                               if hearts.wrappedValue == 0{
                                   // If no hearts left, show the lose overlay
                                   DispatchQueue.main.async {
                                       self.showLoseOverlay.wrappedValue = true
                                   }
                               }
                               // Flip the cards back after a delay
                               DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                   self.flipCard(at: self.firstIndex)
                                   self.flipCard(at: self.secondIndex)
                                   self.firstIndex = -1
                                   self.secondIndex = -1
                                   self.isChecking = false
                               }
                           }
                       }

                       func checkWinCondition() {
                           if matched.allSatisfy({ $0 }) {
                               // If all cards are matched, show the win overlay
                               DispatchQueue.main.async {
                                   self.playSoundWin()
                                   self.showWinOverlay.wrappedValue = true
                               }
                           }
                       }

                       func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
                           guard let arView = arView else { return }
                           for anchor in anchors {
                               if let planeAnchor = anchor as? ARPlaneAnchor {
                                   let anchorEntity = AnchorEntity(anchor: planeAnchor)
                                   arView.scene.addAnchor(anchorEntity)
                                   
                                   addCards(to: anchorEntity)
                                   
                                   DispatchQueue.main.async {
                                       self.showOverlay.wrappedValue = false
                                   }
                               }
                           }
                       }
                       
                       func addCards(to anchorEntity: AnchorEntity) {
                           var cards: [Entity] = []
                           
                           let orangeFruit = try! ModelEntity.loadModel(named: "orange_fruit.usdz")
                           let dragonFruit = try! ModelEntity.loadModel(named: "dragon_fruit.usdz")
                           let watermelonFruit = try! ModelEntity.loadModel(named: "watermelon_fruit.usdz")
                           let kiwiFruit = try! ModelEntity.loadModel(named: "kiwi_fruit.usdz")
                           let peachFruit = try! ModelEntity.loadModel(named: "peach_fruit.usdz")
                           let strawberryFruit = try! ModelEntity.loadModel(named: "strawberry_fruit.usdz")
                           
                           let assets: [(entity: ModelEntity, filename: String)] = [
                               (orangeFruit, "orange_fruit.usdz"),
                               (orangeFruit, "orange_fruit.usdz"),
                               (dragonFruit, "dragon_fruit.usdz"),
                               (dragonFruit, "dragon_fruit.usdz"),
                               (watermelonFruit, "watermelon_fruit.usdz"),
                               (watermelonFruit, "watermelon_fruit.usdz"),
                               (kiwiFruit, "kiwi_fruit.usdz"),
                               (kiwiFruit, "kiwi_fruit.usdz"),
                               (peachFruit, "peach_fruit.usdz"),
                               (peachFruit, "peach_fruit.usdz"),
                               (strawberryFruit, "strawberry_fruit.usdz"),
                               (strawberryFruit, "strawberry_fruit.usdz")
                           ]

                           let shuffledPositions = [
                               (0, 0), (0, 1), (0, 2), (0, 3),
                               (1, 0), (1, 1), (1, 2), (1, 3),
                               (2, 0), (2, 1), (2, 2), (2, 3)
                           ].shuffled()

                           for i in 0..<12 {
                               let box = MeshResource.generateBox(width: 0.2, height: 0.01, depth: 0.2)
                               let material = SimpleMaterial(color: .gray, isMetallic: true)
                               let cardEntity = ModelEntity(mesh: box, materials: [material])
                               cardEntity.generateCollisionShapes(recursive: true)
                               cardEntity.name = "card"

                               let asset = assets[i]
                               let assetEntity = asset.entity.clone(recursive: true)
                               assetEntity.name = asset.filename
                               print(asset.filename)

                               if asset.filename == "watermelon_fruit.usdz" {
                                   assetEntity.scale = [0.002, 0.002, 0.002]
                               } else if asset.filename == "strawberry_fruit.usdz" {
                                   assetEntity.scale = [0.0024, 0.0024, 0.0024]
                               } else if asset.filename == "kiwi_fruit.usdz" {
                                   assetEntity.scale = [0.0007, 0.0007, 0.0007]
                               } else {
                                   assetEntity.scale = [0.0002, 0.0002, 0.0002]
                               }

                               assetEntity.position = [0, 0.06, 0]
                               assetEntity.isEnabled = false

                               let parentEntity = Entity()
                               parentEntity.addChild(cardEntity)
                               parentEntity.addChild(assetEntity)

                               let light = createCardLight()
                               parentEntity.addChild(light)

                               let (x, z) = shuffledPositions[i]
                               parentEntity.position = [Float(x) * 0.4, 0, Float(z) * 0.4]
                               cards.append(parentEntity)

                               anchorEntity.addChild(parentEntity)

                               print("Added card and asset with positions: \(x), \(z)")
                               print("Card and asset added at index \(i): \(asset.filename)")
                           }

                           self.cards = cards
                       }

                       func createCardLight() -> Entity {
                           let light = PointLight()
                           light.light.intensity = 2000
                           light.position = [0, 0.5,0]
                           return light
                       }
                       
                       func playSoundWin() {
                           guard let url = Bundle.main.url(forResource: "win", withExtension: "mp3") else {
                               print("Sound file not found.")
                               return
                           }
                           do {
                               // Create audio player
                               audioPlayer = try AVAudioPlayer(contentsOf: url)
                               // Play the sound
                               audioPlayer?.play()
                           } catch {
                               print("Error playing sound: \(error.localizedDescription)")
                           }
                       }
                       
                       func playSound() {
                           guard let url = Bundle.main.url(forResource: "hamSoundTrim", withExtension: "wav") else {
                               print("Sound file not found.")
                               return
                           }
                           do {
                               // Create audio player
                               audioPlayer = try AVAudioPlayer(contentsOf: url)
                               // Play the sound
                               audioPlayer?.play()
                           } catch {
                               print("Error playing sound: \(error.localizedDescription)")
                           }
                       }
                       
                       func resetGame() {
                           guard let arView = arView else { return }
                           arView.scene.anchors.removeAll()
                           cards.removeAll()
                           isFlipped = Array(repeating: false, count: 12)
                           matched = Array(repeating: false, count: 12)
                           firstIndex = -1
                           secondIndex = -1
                           isChecking = false
                           hearts.wrappedValue  = 3 // Reset hearts count

                           // Restart the AR session
                           let configuration = ARWorldTrackingConfiguration()
                           configuration.planeDetection = .horizontal
                           arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                           
                           // Add cards again
                           guard let anchor = arView.session.currentFrame?.anchors.first(where: { $0 is ARPlaneAnchor }) as? ARPlaneAnchor else { return }
                           let anchorEntity = AnchorEntity(anchor: anchor)
                           arView.scene.addAnchor(anchorEntity)
                           addCards(to: anchorEntity)
                           
                           DispatchQueue.main.async {
                               self.showOverlay.wrappedValue = true
                               self.showWinOverlay.wrappedValue = false
                               self.showLoseOverlay.wrappedValue = false
                           }
                       }

                   }
               }

