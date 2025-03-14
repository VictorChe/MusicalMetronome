import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: MetronomeModel

    var body: some View {
        Form {
            Section(header: Text("Темп")) {
                Slider(value: $model.tempo, in: 60...120, step: 1) {
                    Text("Темп")
                } minimumValueLabel: {
                    Text("60")
                } maximumValueLabel: {
                    Text("120")
                }
                Text("\(Int(model.tempo)) BPM")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.title2)
            }

            Section(header: Text("Длительность")) {
                Slider(value: $model.duration, in: 10...30, step: 1) {
                    Text("Длительность")
                } minimumValueLabel: {
                    Text("10с")
                } maximumValueLabel: {
                    Text("30с")
                }
                Text("\(Int(model.duration)) секунд")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.title2)
            }

            Section(header: Text("Режим тренировки")) {
                Picker("Режим", selection: $model.mode) {
                    ForEach(MetronomeModel.TrainingMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                // Компенсация задержки (только для режима микрофона)
                if model.mode == .microphone {
                    VStack(alignment: .leading) {
                        Text("Компенсация задержки: \(Int(model.latencyCompensation)) мс")
                        Slider(value: $model.latencyCompensation, in: -200...200, step: 5)
                    }
                    .padding(.vertical)

                    Text("Используйте эту настройку, если вы заметили систематическое опережение или отставание в режиме микрофона. Положительные значения - если ваш звук обнаруживается с опозданием, отрицательные - если слишком рано.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Настройки")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(model: MetronomeModel())
    }
}