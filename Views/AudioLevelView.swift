
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

struct AudioLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AudioLevelView(level: 0.5)
            .frame(height: 100)
            .padding()
    }
}
import SwiftUI

struct AudioLevelView: View {
    var level: Double
    private let maxLevel: Double = 1.0
    
    var body: some View {
        VStack {
            Text("Уровень звука")
                .font(.caption)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фоновая полоса
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    // Индикатор уровня
                    Rectangle()
                        .fill(levelColor)
                        .frame(width: geometry.size.width * CGFloat(min(level / maxLevel, 1.0)))
                }
                .cornerRadius(5)
            }
            .frame(height: 30)
            
            // Маркеры уровня
            HStack {
                Text("0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Уровень: \(Int(level * 100))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("100")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var levelColor: Color {
        let normalizedLevel = min(level / maxLevel, 1.0)
        
        if normalizedLevel < 0.3 {
            return .green
        } else if normalizedLevel < 0.7 {
            return .yellow
        } else {
            return .red
        }
    }
}
