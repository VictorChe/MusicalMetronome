
import SwiftUI
import Foundation

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
    
    @State private var pulseOpacity: Double = 0.1
    @State private var pulseCycle = 0
    
    var body: some View {
        VStack {
            HStack(spacing: 2) {
                ForEach(Array(pattern.symbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.system(size: 24))
                        .id("\(pattern.rawValue)-\(index)-\(symbol)")
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
            ZStack {
                // Background fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.blue.opacity(pulseOpacity) : Color.white)
                
                // Border
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.blue : Color.gray, lineWidth: isActive ? 2 : 1)
            }
        )
        .onTapGesture {
            onTap()
        }
        .onChange(of: isActive) { _, nowActive in
            if nowActive {
                // Reset animation cycle when pattern becomes active
                pulseCycle = 0
                startPulseAnimation()
            } else {
                pulseOpacity = 0.1
            }
        }
    }
    
    private func startPulseAnimation() {
        guard isActive else { return }
        
        // If pattern has multiple notes, show more pulses
        let noteCount = max(1, pattern.noteTimings.count)
        
        // Only animate for the number of notes in the pattern
        if pulseCycle < noteCount {
            withAnimation(.easeInOut(duration: 0.3)) {
                pulseOpacity = 0.6
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    pulseOpacity = 0.1
                }
                
                pulseCycle += 1
                
                // Continue pulsing if more notes in the pattern
                if pulseCycle < noteCount && isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        startPulseAnimation()
                    }
                }
            }
        }
    }
}
