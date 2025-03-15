
import SwiftUI

struct RhythmPatternsView: View {
    @ObservedObject var model: MetronomeModel
    var onPatternTapped: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Ритмические фигуры:")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(0..<model.currentPatterns.count, id: \.self) { index in
                    RhythmPatternCard(
                        pattern: model.currentPatterns[index],
                        isActive: index == model.currentBeat % 4
                    )
                    .frame(height: 80)
                    .onTapGesture {
                        onPatternTapped(index)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RhythmPatternCard: View {
    let pattern: MetronomeModel.RhythmPattern
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.blue.opacity(0.2) : Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
            
            VStack {
                Text(pattern.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 5) {
                    ForEach(pattern.symbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.blue : Color.gray.opacity(0.2), lineWidth: 2)
        )
    }
}

struct RhythmPatternsView_Previews: PreviewProvider {
    static var previews: some View {
        let model = MetronomeModel()
        model.currentPatterns = [
            .quarter,
            .eighthPair,
            .eighthTriplet,
            .restEighthNote
        ]
        
        return RhythmPatternsView(model: model, onPatternTapped: { _ in })
    }
}
