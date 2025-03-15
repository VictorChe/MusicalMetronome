
import SwiftUI

struct AudioLevelView: View {
    var level: Double
    @State private var phase: CGFloat = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { index in
                    Rectangle()
                        .fill(barColor(for: index))
                        .frame(width: 10)
                        .frame(height: barHeight(for: index))
                        .cornerRadius(5)
                }
            }
            
            AnimatedWaveformView(level: level, phase: phase)
                .frame(height: 60)
                .padding(.vertical, 5)
            
            Text("Микрофон активен")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onReceive(timer) { _ in
            // Обновляем фазу для анимации движения
            phase += level * 0.3 + 0.1
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

struct AnimatedWaveformView: View {
    var level: Double
    var phase: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let midHeight = height / 2
            let amplitude = midHeight * CGFloat(level) * 0.8
            
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midHeight))
                    
                    for x in stride(from: 0, to: width, by: 1) {
                        let relativeX = x / width
                        let frequency = 20.0 + level * 10
                        let y = midHeight + sin(relativeX * frequency + phase) * amplitude
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                },
                with: .color(Color.blue),
                lineWidth: 2
            )
        }
        .background(Color.black.opacity(0.05))
        .cornerRadius(10)
    }
}

struct BarsView: View {
    var level: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<30, id: \.self) { index in
                Rectangle()
                    .fill(barColor(for: index))
                    .frame(width: 3)
                    .frame(height: barHeight(for: index))
                    .cornerRadius(1.5)
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let maxHeight: Double = 40.0
        let minHeight: Double = 3.0
        let position = Double(index) / 30.0
        
        // Создаем эффект эквалайзера
        let random = sin(position * 10 + Double(index) * 0.3) * 0.3 + 0.7
        let levelContribution = level * random
        
        return minHeight + (maxHeight - minHeight) * levelContribution
    }
    
    private func barColor(for index: Int) -> Color {
        let position = Double(index) / 30.0
        
        // Градиент цветов в зависимости от позиции и уровня звука
        if level > 0.7 {
            return Color(hue: 0.6 - (position * 0.6), saturation: 0.8, brightness: 0.9)
        } else if level > 0.4 {
            return Color(hue: 0.3 + (position * 0.3), saturation: 0.7, brightness: 0.8)
        } else {
            return Color(hue: 0.5, saturation: 0.5 * level, brightness: 0.7)
                .opacity(0.3 + level * 0.7)
        }
    }
}

struct AudioLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AudioLevelView(level: 0.5)
            .frame(height: 200)
            .padding()
    }
}
