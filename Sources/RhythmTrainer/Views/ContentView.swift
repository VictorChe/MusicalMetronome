import SwiftUI

struct ContentView: View {
    @StateObject private var metronomeModel = MetronomeModel()
    @State private var isTraining = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Ритм-тренер")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)

                // Информация о текущих настройках
                VStack(spacing: 10) {
                    settingsRow(icon: "metronome", text: "\(Int(metronomeModel.tempo)) BPM")
                    settingsRow(icon: "clock", text: "\(Int(metronomeModel.duration)) секунд")
                    settingsRow(
                        icon: metronomeModel.mode == .tap ? "hand.tap" : "mic",
                        text: metronomeModel.mode.rawValue
                    )
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(15)

                Spacer()

                // Навигационные кнопки
                NavigationLink {
                    SettingsView(model: metronomeModel)
                } label: {
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

                Button {
                    isTraining = true
                } label: {
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

                Spacer()

                Text("Rhythm Trainer MVP")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .navigationDestination(isPresented: $isTraining) {
                TrainingView(model: metronomeModel)
                    .onAppear {
                        metronomeModel.startMetronome()
                    }
            }
        }
    }

    private func settingsRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
            Text(text)
                .font(.title2)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}