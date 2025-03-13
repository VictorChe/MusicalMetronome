import SwiftUI

struct ContentView: View {
    @StateObject private var metronomeModel = MetronomeModel()
    @State private var isTraining = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Ритм-тренер")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "metronome")
                            .font(.title)
                        Text("\(Int(metronomeModel.tempo)) BPM")
                            .font(.title2)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.title)
                        Text("\(Int(metronomeModel.duration)) секунд")
                            .font(.title2)
                    }
                    
                    HStack {
                        Image(systemName: metronomeModel.mode == .tap ? "hand.tap" : "mic")
                            .font(.title)
                        Text(metronomeModel.mode.rawValue)
                            .font(.title2)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(15)
                
                Spacer()
                
                NavigationLink(destination: SettingsView(model: metronomeModel)) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Настройки")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                NavigationLink(
                    destination: TrainingView(model: metronomeModel)
                        .onAppear {
                            metronomeModel.startMetronome()
                        },
                    isActive: $isTraining
                ) {
                    Button(action: {
                        isTraining = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Начать тренировку")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Text("Rhythm Trainer MVP")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
