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

                if model.mode == .microphone {
                    Text("Требуется доступ к микрофону")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Калибровка задержки"), footer: Text("Рекомендуемые значения: AirPods: 50-70 мс, обычные наушники: 30-50 мс, через динамик: 100-150 мс")) {
                Slider(value: $model.latencyCompensation, in: 0...200, step: 1) {
                    Text("Компенсация задержки")
                } minimumValueLabel: {
                    Text("0 мс")
                } maximumValueLabel: {
                    Text("200 мс")
                }
                Text("\(Int(model.latencyCompensation)) мс")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.headline)

                Toggle("Автоматическая калибровка", isOn: .constant(false))
                    .disabled(true) // Будущая функция, пока недоступна
                    .foregroundColor(.gray)
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