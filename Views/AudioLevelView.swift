import SwiftUI

struct BarsView: View {
    let level: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { index in
                Rectangle()
                    .fill(barColor(for: index))
                    .frame(width: 10)
                    .frame(height: barHeight(for: index))
                    .cornerRadius(5)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: Double = 20.0
        let maxHeight: Double = 100.0
        let threshold = Double(index) * 0.2
        let scaledLevel = min(max(0, level - threshold) * 2, 1)
        return baseHeight + (maxHeight - baseHeight) * scaledLevel
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Double(index) * 0.2
        if level > threshold + 0.8 {
            return .red
        } else if level > threshold + 0.5 {
            return .orange
        } else if level > threshold {
            return .green
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

struct AudioLevelView: View {
    var level: Double

    var body: some View {
        VStack(spacing: 8) {
            BarsView(level: level)

            WaveformView(level: level)
                .frame(height: 60)
                .padding(.vertical, 5)

            Text("Микрофон активен")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AudioLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AudioLevelView(level: 0.5)
            .frame(height: 100)
            .padding()
    }
}

struct WaveformView: View {
    var level: Double
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midHeight = height / 2

                // Создаем градиент
                let colors = [Color.blue, Color.purple, Color.pink]
                let gradient = Gradient(colors: colors)

                // Создаем путь для волны
                var path = Path()
                path.move(to: CGPoint(x: 0, y: midHeight))

                // Обновляем фазу для создания анимации движения
                phase -= 2
                if phase <= -width {
                    phase = 0
                }

                // Рисуем волну
                let waves = 3 // Количество волн
                let amplitude = midHeight * min(CGFloat(level) * 0.8 + 0.2, 0.8) // Высота волны зависит от уровня звука

                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / width
                    let sine = sin((relativeX * .pi * 2 * CGFloat(waves)) + phase / 20)
                    let y = midHeight + sine * amplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                // Завершаем путь
                path.addLine(to: CGPoint(x: width, y: midHeight))

                // Рисуем волну с градиентом
                context.stroke(
                    path,
                    with: .color(Color.blue.opacity(0.7)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct BarsView_Previews: PreviewProvider {
    static var previews: some View {
        BarsView(level: 0.7)
            .frame(height: 80)
            .padding()
    }
}