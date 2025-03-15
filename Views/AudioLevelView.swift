import SwiftUI

struct AudioLevelView: View {
    var level: Double
    var isBeatDetected: Bool
    var showWaveform: Bool = true
    var beats: [Double] = []
    var currentBeatPosition: Double = 0
    var userHits: [(time: Double, accuracy: Double)] = []

    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Фон
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.black.opacity(0.05))

                // Индикатор текущего бита
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 2)
                    .offset(x: geometry.size.width * CGFloat(currentBeatPosition / Double(beats.last ?? 1.0)))

                // Визуализация битов
                ForEach(beats.indices, id: \.self) { i in
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1, height: geometry.size.height)
                        .position(x: CGFloat(beats[i] / Double(beats.last ?? 1.0)) * geometry.size.width,
                                  y: geometry.size.height / 2)
                }

                // Визуализация попаданий пользователя
                ForEach(userHits.indices, id: \.self) { i in
                    let hit = userHits[i]
                    Circle()
                        .fill(getAccuracyColor(accuracy: hit.accuracy))
                        .frame(width: 6, height: 6)
                        .position(
                            x: CGFloat(hit.time / Double(beats.last ?? 1.0)) * geometry.size.width,
                            y: geometry.size.height * 0.5
                        )
                }

                if showWaveform {
                    // Волновой индикатор уровня звука
                    HStack(spacing: barSpacing) {
                        ForEach(0..<Int(geometry.size.width / (barWidth + barSpacing)), id: \.self) { i in
                            let randomHeight = Double.random(in: 0...(isBeatDetected ? 1.0 : level))
                            Rectangle()
                                .fill(
                                    isBeatDetected ?
                                        Color.green :
                                        Color.blue.opacity(max(0.3, level))
                                )
                                .frame(width: barWidth, height: CGFloat(randomHeight * geometry.size.height))
                        }
                    }
                } else {
                    // Простой индикатор уровня для режима тапов
                    Rectangle()
                        .fill(
                            isBeatDetected ?
                                Color.green.opacity(0.8) :
                                Color.blue.opacity(max(0.3, level))
                        )
                        .frame(width: geometry.size.width * CGFloat(level))
                }
            }
        }
    }

    private func getAccuracyColor(accuracy: Double) -> Color {
        if accuracy <= 0.05 {
            return .green
        } else if accuracy <= 0.15 {
            return .blue
        } else {
            return .orange
        }
    }
}

struct AudioLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AudioLevelView(
            level: 0.7,
            isBeatDetected: true,
            showWaveform: true,
            beats: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
            currentBeatPosition: 3.5,
            userHits: [
                (time: 1.0, accuracy: 0.02),
                (time: 2.1, accuracy: 0.08),
                (time: 3.0, accuracy: 0.2)
            ]
        )
        .frame(height: 100)
        .padding()
        .background(Color.black.opacity(0.1))
    }
}