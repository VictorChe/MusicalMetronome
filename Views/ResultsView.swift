
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

            // Спектрограмма или визуализация попаданий
            VStack(alignment: .leading) {
                Text("Визуализация попаданий:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                // Добавляем упрощенную визуализацию попаданий - схожую с AudioLevelView
                HStack(spacing: 2) {
                    ForEach(0..<min(20, model.totalBeats), id: \.self) { i in
                        let height = getBarHeight(for: i)
                        let color = getBarColor(for: i)
                        
                        Rectangle()
                            .fill(color)
                            .frame(height: height * 60)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 60)
                .padding(.bottom, 10)
                
                // Легенда
                HStack(spacing: 15) {
                    HStack(spacing: 5) {
                        Circle().fill(Color.green).frame(width: 10, height: 10)
                        Text("Идеальные").font(.caption)
                    }
                    
                    HStack(spacing: 5) {
                        Circle().fill(Color.blue).frame(width: 10, height: 10)
                        Text("Хорошие").font(.caption)
                    }
                    
                    HStack(spacing: 5) {
                        Circle().fill(Color.orange).frame(width: 10, height: 10)
                        Text("Неточные").font(.caption)
                    }
                    
                    HStack(spacing: 5) {
                        Circle().fill(Color.red).frame(width: 10, height: 10)
                        Text("Пропущенные").font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
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
    
    // Генерируем высоту столбца для визуализации
    private func getBarHeight(for index: Int) -> Double {
        // Упрощенная логика - рандомизируем высоту на основе результатов
        let totalGoodHits = model.perfectHits + model.goodHits
        let ratio = Double(totalGoodHits) / Double(max(1, model.totalBeats))
        
        // Случайная высота, но с тенденцией соответствовать общей точности
        let randomFactor = Double.random(in: 0.7...1.3)
        return min(1.0, max(0.1, ratio * randomFactor))
    }
    
    // Определяем цвет бара для визуализации
    private func getBarColor(for index: Int) -> Color {
        // Упрощенная логика для распределения цветов
        let perfectRatio = Double(model.perfectHits) / Double(max(1, model.totalBeats))
        let goodRatio = Double(model.goodHits) / Double(max(1, model.totalBeats))
        let missedRatio = Double(model.missedHits) / Double(max(1, model.totalBeats))
        
        let rand = Double.random(in: 0...1.0)
        
        if rand < perfectRatio {
            return .green
        } else if rand < perfectRatio + goodRatio {
            return .blue
        } else if rand < perfectRatio + goodRatio + missedRatio {
            return .orange
        } else {
            return .red
        }
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
