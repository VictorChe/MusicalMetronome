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
    @State private var phase = 0.0
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    private func calculateWaveY(x: CGFloat, width: CGFloat, midHeight: CGFloat, amplitude: CGFloat) -> CGFloat {
        let relativeX = x / width
        let frequency = 10.0
        
        let sin1 = sin(relativeX * .pi * 2 * frequency + phase)
        let sin2 = sin(relativeX * .pi * 2 * frequency * 0.5 + phase * 1.5)
        let combinedSin = sin1 * 0.7 + sin2 * 0.3
        
        return midHeight + CGFloat(combinedSin) * amplitude
    }
    
    private func createWavePath(size: CGSize) -> Path {
        let width = size.width
        let height = size.height
        let midHeight = height / 2
        let amplitude = CGFloat(level * height * 0.8)
        
        var path = Path()
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let y = calculateWaveY(x: x, width: width, midHeight: midHeight, amplitude: amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midHeight = height / 2
                let amplitude = CGFloat(level * height * 0.8)
                let path = createWavePath(size: size)
                
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
                
                context.stroke(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: midHeight),
                        endPoint: CGPoint(x: width, y: midHeight)
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
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

struct AudioLevelView_Previews_2: PreviewProvider {
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