import SwiftUI
import Foundation

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

                NavigationLink(destination: TrainingView(model: metronomeModel)) {
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

                Text("Версия 1.0")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }

    private func settingsRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)

            Text(text)
                .font(.body)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}