
import SwiftUI

struct AudioLevelView: View {
    var level: Double
    var isBeatDetected: Bool = false
    var showWaveform: Bool = true
    var beats: [Double] = []
    var currentBeatPosition: Double = 0
    var userHits: [(time: Double, accuracy: Double)] = []
    @State private var scrollOffset: CGFloat = 0
    @State private var isFullScreen: Bool = false
    
    let numberOfVisibleBeats: Int = 8
    let beatLineColor = Color.gray.opacity(0.7)
    let waveColor = Color.blue.opacity(0.5)
    let accuracyColors: [Color] = [.green, .blue, .orange, .red]
    
    var body: some View {
        ZStack {
            // Подложка для полноэкранного режима
            if isFullScreen {
                Color.black.opacity(0.1)
                    .cornerRadius(8)
                    .edgesIgnoringSafeArea(.all)
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                ZStack {
                    // Фоновая сетка с вертикальными линиями тактов
                    HStack(spacing: 0) {
                        ForEach(0..<max(beats.count, 16), id: \.self) { i in
                            GeometryReader { geo in
                                VStack {
                                    // Вертикальная линия такта
                                    Rectangle()
                                        .fill(beatLineColor)
                                        .frame(width: 1)
                                        .frame(height: geo.size.height * 0.8)
                                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                    
                                    // Номер такта
                                    Text("\(i + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 50)
                        }
                    }
                    .frame(height: 80)
                    
                    // Горизонтальная линия времени
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                        }
                        .stroke(Color.gray, lineWidth: 1)
                    }
                    
                    // Отметки попаданий пользователя
                    ForEach(userHits.indices, id: \.self) { index in
                        let hit = userHits[index]
                        let beatWidth: CGFloat = 50
                        let xPosition = CGFloat(hit.time) * beatWidth
                        let colorIndex = min(Int(abs(hit.accuracy) * 10), accuracyColors.count - 1)
                        
                        Circle()
                            .fill(accuracyColors[colorIndex])
                            .frame(width: 10, height: 10)
                            .position(x: xPosition, y: 40) // Расположение на горизонтальной линии
                    }
                    
                    // Текущая позиция проигрывания
                    GeometryReader { geo in
                        let beatWidth: CGFloat = 50
                        let xPosition = CGFloat(currentBeatPosition) * beatWidth
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2)
                            .frame(height: geo.size.height * 0.9)
                            .position(x: xPosition, y: geo.size.height / 2)
                    }
                    
                    // Волна аудио (только для режима микрофона)
                    if showWaveform {
                        // Визуализация уровня звука в виде волны
                        GeometryReader { geo in
                            let maxHeight = geo.size.height * 0.7
                            let centerY = geo.size.height / 2
                            
                            // Динамическая волна на основе уровня аудио
                            Path { path in
                                let waveWidth = geo.size.width * 0.2
                                let amplitude = maxHeight * CGFloat(level)
                                
                                path.move(to: CGPoint(x: geo.size.width - waveWidth, y: centerY))
                                
                                // Создаем волновой эффект
                                for i in 0...100 {
                                    let x = geo.size.width - waveWidth + CGFloat(i) * waveWidth / 100
                                    let y = centerY + sin(CGFloat(i) * 0.2 + CGFloat(Date().timeIntervalSince1970 * 10)) * amplitude
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            .stroke(waveColor, lineWidth: 3)
                            
                            // Усиленная визуализация при обнаружении звука
                            if isBeatDetected {
                                Path { path in
                                    let waveWidth = geo.size.width * 0.2
                                    let amplitude = maxHeight * 0.8 // Больше амплитуда
                                    
                                    path.move(to: CGPoint(x: geo.size.width - waveWidth, y: centerY))
                                    
                                    for i in 0...100 {
                                        let x = geo.size.width - waveWidth + CGFloat(i) * waveWidth / 100
                                        let y = centerY + sin(CGFloat(i) * 0.3 + CGFloat(Date().timeIntervalSince1970 * 15)) * amplitude
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                                .stroke(Color.green, lineWidth: 3)
                            }
                        }
                    }
                }
                .frame(width: CGFloat(max(beats.count, 16)) * 50, height: 80)
            }
        }
        .onTapGesture {
            withAnimation {
                isFullScreen.toggle()
            }
        }
    }
}

struct AudioLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AudioLevelView(
            level: 0.3,
            isBeatDetected: true,
            showWaveform: true,
            beats: [1, 2, 3, 4, 5, 6, 7, 8],
            currentBeatPosition: 2.5,
            userHits: [
                (time: 1.1, accuracy: 0.1),
                (time: 2.05, accuracy: 0.05),
                (time: 3.2, accuracy: 0.2)
            ]
        )
        .frame(height: 80)
        .previewLayout(.sizeThatFits)
    }
}
