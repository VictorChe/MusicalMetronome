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

            AnimatedWaveformView(level: level)
                .frame(height: 60)
                .padding(.vertical, 5)

            Text("Микрофон активен")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Улучшенная анимированная визуализация звуковой волны
struct AnimatedWaveformView: View {
    var level: Double
    @State private var phase: Double = 0

    // Используем таймер для гладкой анимации
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Настройки волны
                let width = size.width
                let height = size.height
                let midHeight = height / 2
                let amplitude = midHeight * min(CGFloat(level) * 0.8 + 0.2, 0.8)
                let frequency: Double = 0.6 + (level * 2) // Частота зависит от уровня звука
                let waves: Double = 5 // Количество волн

                // Создаем путь для волны
                var path = Path()
                path.move(to: CGPoint(x: 0, y: midHeight))

                // Рисуем волну
                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = Double(x) / Double(width)
                    let normalizedPhase = phase.truncatingRemainder(dividingBy: 2 * .pi)
                    let sine = sin((relativeX * .pi * 2 * waves * frequency) + normalizedPhase)
                    let y = midHeight + sine * CGFloat(amplitude)
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                // Градиент для визуализации
                let gradient = Gradient(colors: [
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.7),
                    Color.pink.opacity(0.7)
                ])

                // Настройки отображения
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [.blue, .purple]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: width, y: 0)
                    ),
                    lineWidth: 3
                )

                // Дополнительная волна с задержкой для эффекта объема
                var secondPath = Path()
                secondPath.move(to: CGPoint(x: 0, y: midHeight))

                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = Double(x) / Double(width)
                    let normalizedPhase = (phase - 0.5).truncatingRemainder(dividingBy: 2 * .pi)
                    let sine = sin((relativeX * .pi * 2 * waves * frequency) + normalizedPhase)
                    let y = midHeight + sine * CGFloat(amplitude * 0.7)
                    secondPath.addLine(to: CGPoint(x: x, y: y))
                }

                context.stroke(
                    secondPath,
                    with: .color(Color.purple.opacity(0.5)),
                    lineWidth: 2
                )
            }
            .background(Color.black.opacity(0.05))
            .cornerRadius(10)
            .onReceive(timer) { _ in
                // Обновляем фазу для анимации движения
                phase += level * 0.3 + 0.1
                if phase > .pi * 2 {
                    phase -= .pi * 2
                }
            }
        }
    }
}

struct AudioLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AudioLevelView(level: 0.5)
            .frame(height: 120)
            .padding()
    }
}