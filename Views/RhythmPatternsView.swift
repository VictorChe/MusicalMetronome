
import SwiftUI

struct RhythmPatternsView: View {
    @ObservedObject var model: MetronomeModel
    var onPatternTapped: ((Int) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Текущие паттерны:")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack(spacing: 15) {
                ForEach(0..<model.currentPatterns.count, id: \.self) { index in
                    PatternView(
                        pattern: model.currentPatterns[index],
                        isActive: getActiveIndex() == index,
                        onTap: {
                            onPatternTapped?(index)
                        }
                    )
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // Определяем текущий активный паттерн на основе текущего бита
    private func getActiveIndex() -> Int {
        if model.currentBeat <= 0 {
            return 0
        }
        
        return (model.currentBeat - 1) % 4
    }
}

struct PatternView: View {
    let pattern: MetronomeModel.RhythmPattern
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            HStack(spacing: 2) {
                ForEach(pattern.symbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 24))
                }
            }
            
            Text(pattern.rawValue)
                .font(.caption)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(minWidth: 60)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.blue : Color.gray, lineWidth: isActive ? 2 : 1)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? Color.blue.opacity(0.1) : Color.white)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}
