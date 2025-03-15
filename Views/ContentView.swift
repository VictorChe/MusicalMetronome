import SwiftUI
import AVFoundation

struct SettingsView: View {
    var body: some View {
        Text("Settings")
    }
}

struct TrainingView: View {
    @ObservedObject var metronomeModel: MetronomeModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isTrainingComplete = false

    var body: some View {
        VStack {
            Text("Training View")
            Button("Stop Training") {
                metronomeModel.stop()
                isTrainingComplete = true
                // Add any other necessary cleanup here.
            }
            if isTrainingComplete{
                Button("Show Results"){
                    NotificationCenter.default.post(name: Notification.Name("ReturnToMainScreen"), object: nil)
                }
            }
        }
    }
}

struct ResultsView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack{
            Text("Results View")
            Button("Back to Main") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}


struct ContentView: View {
    @StateObject private var metronomeModel = MetronomeModel()
    @State private var isSettingsActive = false
    @State private var isTrainingActive = false
    @State private var navigationTag: Int? = nil

    let returnNotification = NotificationCenter.default

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                .onAppear {
                    returnNotification.addObserver(forName: Notification.Name("ReturnToMainScreen"),
                                                 object: nil,
                                                 queue: .main) { _ in
                        isTrainingActive = false
                        isSettingsActive = false
                        navigationTag = nil
                        metronomeModel.stop()
                    }
                }
                .onDisappear {
                    returnNotification.removeObserver(self)
                }

                NavigationLink(destination: SettingsView(), isActive: $isSettingsActive) {
                    EmptyView()
                }

                NavigationLink(destination: TrainingView(metronomeModel: metronomeModel), isActive: $isTrainingActive) {
                    EmptyView()
                }
                
                NavigationLink(destination: ResultsView(), tag: 1, selection: $navigationTag){
                    EmptyView()
                }

                Button("Start Training") {
                    isTrainingActive = true
                    metronomeModel.start()
                }

                Button("Settings") {
                    isSettingsActive = true
                }
            }
            .navigationTitle("Metronome Trainer")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}