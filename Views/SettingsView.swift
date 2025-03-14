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

                    VStack(alignment: .leading) {
                        Text("Компенсация задержки (мс)")
                            .font(.caption)

                        Slider(value: $model.latencyCompensation, in: -200...200, step: 5) {
                            Text("Компенсация задержки")
                        } minimumValueLabel: {
                            Text("-200")
                        } maximumValueLabel: {
                            Text("200")
                        }

                        Text("\(Int(model.latencyCompensation)) мс")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.callout)

                        Text("Отрицательные значения для наушников, положительные для динамиков")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
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