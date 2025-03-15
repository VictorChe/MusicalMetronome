
import SwiftUI

struct AudioLevelView: View {
    var level: Double

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

            Text("Микрофон активен")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: Double = 20.0
        let maxHeight: Double = 100.0
        let threshold = Double(index) * 0.2
        
        let normalizedLevel = level - threshold
        let clampedLevel = max(0, normalizedLevel)
        let scaledLevel = min(clampedLevel * 2, 1)
        
        let heightDifference = maxHeight - baseHeight
        let additionalHeight = heightDifference * scaledLevel
        
        return baseHeight + additionalHeight
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Double(index) * 0.2
        let levelAboveThreshold = level - threshold
        
        if levelAboveThreshold > 0.8 {
            return .red
        }
        if levelAboveThreshold > 0.5 {
            return .orange
        }
        if levelAboveThreshold > 0 {
            return .green
        }
        return Color.gray.opacity(0.3)
    }
}

// Оставляем WaveformView без изменений, так как с ней нет проблем
struct WaveformView: View {
    var level: Double
    @State private var phase = 0.0
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midHeight = height / 2
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                let amplitude = CGFloat(level * height * 0.8)
                let frequency = 10.0
                
                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / width
                    
                    let sin1 = sin(relativeX * .pi * 2 * frequency + phase)
                    let sin2 = sin(relativeX * .pi * 2 * frequency * 0.5 + phase * 1.5)
                    
                    let combinedSin = sin1 * 0.7 + sin2 * 0.3
                    
                    let y = midHeight + CGFloat(combinedSin) * amplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                let highlightPosition = CGPoint(
                    x: width * 0.5, 
                    y: midHeight + CGFloat(sin(phase * 2)) * amplitude
                )
                
                let colors: [Color] = [.blue, .green, level > 0.5 ? .orange : .green, level > 0.8 ? .red : .orange]
                let gradient = Gradient(colors: colors)
                let linearGradient = LinearGradient(
                    gradient: gradient,
                    startPoint: UnitPoint(x: 0, y: 0.5),
                    endPoint: UnitPoint(x: 1, y: 0.5)
                )
                
                context.stroke(path, with: .linearGradient(linearGradient, startPoint: CGPoint(x: 0, y: midHeight), endPoint: CGPoint(x: width, y: midHeight)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                if level > 0.1 {
                    context.fill(
                        Path(ellipseIn: CGRect(x: highlightPosition.x - 5, y: highlightPosition.y - 5, width: 10, height: 10)),
                        with: .color(level > 0.5 ? .orange : .green)
                    )
                }
            }
            .onReceive(timer) { _ in
                phase += 0.1
                if phase > .pi * 2 {
                    phase = 0
                }
            }
            .drawingGroup()
        }
        .background(Color.black.opacity(0.05))
        .cornerRadius(10)
    }
}

struct AudioLevelView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AudioLevelView(level: 0.5)
                .frame(height: 100)
            
            WaveformView(level: 0.7)
                .frame(height: 60)
        }
        .padding()
    }
}
