
import SwiftUI

struct ResultsView: View {
    @ObservedObject var model: MetronomeModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Результаты тренировки")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 15) {
                    ResultRow(label: "Идеальные попадания", value: model.perfectHits, color: .green)
                    ResultRow(label: "Хорошие попадания", value: model.goodHits, color: .blue)
                    ResultRow(label: "Неточные попадания", value: model.missedHits, color: .orange)
                    ResultRow(label: "Пропущенные биты", value: model.skippedBeats, color: .red)
                    ResultRow(label: "Ноты мимо", value: model.extraHits, color: .purple)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(15)

                VStack(spacing: 10) {
                    let totalBeats = model.totalBeats
                    let totalAttempts = model.perfectHits + model.goodHits + model.missedHits + model.extraHits
                    let accuracy = totalBeats > 0 ? Double(model.perfectHits + model.goodHits) / Double(totalBeats + model.extraHits) * 100 : 0
                    
                    Text("Всего битов: \(totalBeats)")
                    Text("Всего попыток: \(totalAttempts)")
                    Text(String(format: "Точность: %.1f%%", accuracy))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()

                Button {
                    dismiss()
                } label: {
                    Text("Закрыть")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()
            }
            .padding()
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
