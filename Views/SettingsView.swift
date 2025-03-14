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

            Section(header: Text("Компенсация задержки")) {
                VStack(alignment: .leading) {
                    Text("Компенсация задержки (мс)")
                        .font(.headline)

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

                    Text("Рекомендуемые настройки:")
                        .font(.subheadline)
                        .padding(.top, 8)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("Наушники:")
                                .fontWeight(.medium)
                            Text("AirPods: -80 до -120 мс")
                            Text("Проводные: -30 до -50 мс")
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Динамик телефона:")
                                .fontWeight(.medium)
                            Text("+30 до +50 мс")
                        }
                    }
                    .padding(.top, 2)

                    Text("Отрицательные значения компенсируют задержку в наушниках, положительные - для динамиков")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
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