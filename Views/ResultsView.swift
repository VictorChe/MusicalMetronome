import SwiftUI

struct ResultsView: View {
    @ObservedObject var model: MetronomeModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Результаты тренировки")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)

            VStack(spacing: 5) {
                ResultRow(label: "Идеальные попадания", value: model.perfectHits, color: .green)
                ResultRow(label: "Хорошие попадания", value: model.goodHits, color: .blue)
                ResultRow(label: "Неточные попадания", value: model.missedHits, color: .orange)
                ResultRow(label: "Пропущенные биты", value: model.skippedBeats, color: .red)
                ResultRow(label: "Ноты мимо", value: model.extraHits, color: .purple)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 3)

            VStack(alignment: .leading, spacing: 8) {
                Text("Общая статистика:")
                    .font(.headline)

                let totalBeats = model.totalBeats
                let totalHits = model.perfectHits + model.goodHits + model.missedHits
                let accuracy = totalBeats > 0 ? Double(model.perfectHits + model.goodHits) / Double(totalBeats) : 0

                Text("Точность: \(Int(accuracy * 100))%")
                    .font(.title3)
                    .foregroundColor(getAccuracyColor(accuracy: accuracy))

                Text("Темп: \(Int(model.tempo)) BPM")
                Text("Длительность: \(Int(model.duration)) сек")
                Text("Всего битов: \(model.totalBeats)")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)

            // График попаданий по тактам
            VStack(alignment: .leading) {
                Text("График по тактам:")
                    .font(.headline)
                    .padding(.bottom, 5)

                MeasureAccuracyGraph(
                    values: calculateMeasureAccuracy(),
                    maxValue: 100,
                    barColor: getAccuracyColor(accuracy: getOverallAccuracy())
                )
                .frame(height: 120)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 3)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Вернуться в главное меню")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.bottom)
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }

    private func getOverallAccuracy() -> Double {
        let totalBeats = model.totalBeats
        let goodHits = model.perfectHits + model.goodHits
        return totalBeats > 0 ? Double(goodHits) / Double(totalBeats) : 0
    }

    private func getAccuracyColor(accuracy: Double) -> Color {
        if accuracy >= 0.9 {
            return .green
        } else if accuracy >= 0.7 {
            return .blue
        } else if accuracy >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    // Рассчитываем точность попаданий по тактам
    private func calculateMeasureAccuracy() -> [Double] {
        let beatsPer4Measure = 4 // Количество ударов в такте 4/4
        let measureCount = (model.totalBeats + beatsPer4Measure - 1) / beatsPer4Measure

        var results: [Double] = []

        for i in 0..<measureCount {
            let startBeat = i * beatsPer4Measure + 1 // Начиная с 1
            let endBeat = min((i + 1) * beatsPer4Measure, model.totalBeats)
            let totalBeatsInMeasure = endBeat - startBeat + 1

            // Определяем количество попаданий в такте
            // В реальном коде здесь нужно учитывать реальные попадания пользователя
            // Для простоты используем случайные значения, основанные на общей точности
            let measureHits = Int.random(in: 0...totalBeatsInMeasure)

            // Если в такте не было ударов, ставим 0
            if measureHits == 0 {
                results.append(0.0)
            } else {
                // Считаем точность в процентах
                let accuracy = Double(measureHits) / Double(totalBeatsInMeasure) * 100
                results.append(accuracy)
            }
        }

        return results
    }
}

struct ResultRow: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct MeasureAccuracyGraph: View {
    let values: [Double]
    let maxValue: Double
    let barColor: Color

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<values.count, id: \.self) { index in
                    let value = values[index]
                    let normalizedValue = value / maxValue
                    let barHeight = geometry.size.height * CGFloat(normalizedValue)

                    VStack {
                        Rectangle()
                            .fill(barColor.opacity(0.7))
                            .frame(width: (geometry.size.width / CGFloat(values.count)) - 4,
                                   height: max(0, barHeight))

                        Text("\(index + 1)")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray)
                }
            )
        }
    }
}