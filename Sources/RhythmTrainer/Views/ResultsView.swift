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
                let accuracy = totalBeats > 0 ? Double(model.perfectHits + model.goodHits) / Double(totalBeats) * 100 : 0
                
                Text("Всего битов: \(totalBeats)")
                Text("Всего попаданий: \(totalHits)")
                Text(String(format: "Точность: %.1f%%", accuracy))
                
                Text("Оценка: \(performanceRating)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 3)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Завершить")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            model.calculateSkippedBeats()
        }
    }
    
    var performanceRating: String {
        let totalBeats = model.totalBeats
        if totalBeats == 0 { return "Н/Д" }
        
        let perfectRatio = Double(model.perfectHits) / Double(totalBeats)
        let goodRatio = Double(model.goodHits) / Double(totalBeats)
        
        if perfectRatio >= 0.8 {
            return "Отлично! 🌟"
        } else if perfectRatio >= 0.6 {
            return "Очень хорошо! 👍"
        } else if perfectRatio + goodRatio >= 0.7 {
            return "Хорошо 👌"
        } else if perfectRatio + goodRatio >= 0.5 {
            return "Неплохо 🙂"
        } else {
            return "Требуется тренировка 💪"
        }
    }
}

struct ResultRow: View {
    var label: String
    var value: Int
    var color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(value)")
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(.vertical, 5)
    }
}
