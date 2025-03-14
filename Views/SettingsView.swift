import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: MetronomeModel
    @State private var showLatencyInfo = false

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
            }

            Section(header: Text("Калибровка задержки")) {
                Slider(value: $model.latencyCompensation, in: -100...100, step: 5) {
                    Text("Компенсация латентности (мс)")
                } minimumValueLabel: {
                    Text("-100")
                } maximumValueLabel: {
                    Text("100")
                }

                Text("Компенсация: \(Int(model.latencyCompensation)) мс")
                    .frame(maxWidth: .infinity, alignment: .center)

                Button(action: {
                    showLatencyInfo.toggle()
                }) {
                    Label("Рекомендации по настройке", systemImage: "info.circle")
                }

                if showLatencyInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Рекомендуемые настройки:")
                            .font(.headline)

                        Text("• Проводные наушники: 0-30 мс")
                            .font(.caption)

                        Text("• AirPods/Bluetooth: 40-80 мс")
                            .font(.caption)

                        Text("• Без наушников: -20-0 мс")
                            .font(.caption)
                            .padding(.bottom, 4)

                        Text("Более высокие значения: если звуки засчитываются поздно")
                            .font(.caption)

                        Text("Более низкие значения: если звуки засчитываются рано")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            Section(header: Text("Улучшение записи звука")) {
                Toggle("Блокировать частые звуки", isOn: .constant(true))
                    .disabled(true) 

                Toggle("Игнорировать эхо метронома", isOn: .constant(true))
                    .disabled(true) 

                if model.mode == .microphone {
                    Text("Рекомендуется снизить громкость метронома при использовании микрофона для уменьшения эхо.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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