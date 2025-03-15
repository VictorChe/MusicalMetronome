import SwiftUI

struct AudioLevelView: View {
    var level: Double
    var isBeatDetected: Bool
    var showWaveform: Bool
    var beats: [Double]
    var currentBeatPosition: Double
    var userHits: [(time: Double, accuracy: Double)]

    @State private var animatedLevel: Double = 0
    @State private var wavePoints: [CGPoint] = []
    @State private var isFullscreen: Bool = false
    @State private var scrollOffset: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Фоновая подложка при полноэкранном режиме
                if isFullscreen {
                    Color.black.opacity(0.9)
                        .ignoresSafeArea()
                }

                // Основной контент
                VStack(spacing: 0) {
                    ZStack {
                        // Фон для спектрограммы
                        Rectangle()
                            .fill(isFullscreen ? Color.gray.opacity(0.1) : Color.clear)
                            .cornerRadius(10)

                        // Горизонтальная центральная линия (временная шкала)
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 1)

                        // Вертикальные линии для каждого бита (доли такта)
                        HStack(spacing: 0) {
                            ForEach(0..<min(beats.count, getVisibleBeatsCount(width: geometry.size.width)), id: \.self) { index in
                                let adjustedIndex = getFirstVisibleBeat() + index
                                if adjustedIndex < beats.count {
                                    Rectangle()
                                        .fill(isBeatActive(beats[adjustedIndex]) ? Color.red : Color.gray.opacity(0.7))
                                        .frame(width: 1, height: geometry.size.height)
                                        .padding(.leading, getBeatPosition(beat: beats[adjustedIndex], width: geometry.size.width) - 1)
                                }
                            }
                        }

                        // Отображение попаданий пользователя
                        ForEach(userHits.indices, id: \.self) { index in
                            let hit = userHits[index]
                            Circle()
                                .fill(getAccuracyColor(hit.accuracy))
                                .frame(width: 6, height: 6)
                                .position(
                                    x: getBeatPosition(beat: hit.time, width: geometry.size.width),
                                    y: geometry.size.height / 2 + (hit.accuracy > 0 ? 5 : -5) // Смещение вверх/вниз от центральной линии
                                )
                                .opacity(isHitVisible(hit.time) ? 1 : 0)
                        }

                        // Аудио волна (только если showWaveform == true)
                        if showWaveform {
                            Path { path in
                                let height = geometry.size.height
                                let width = geometry.size.width

                                // Генерируем аудиоволну, если она еще не существует
                                if wavePoints.isEmpty {
                                    generateWavePoints(width: width, height: height, level: level)
                                }

                                if let firstPoint = wavePoints.first {
                                    path.move(to: firstPoint)

                                    for point in wavePoints.dropFirst() {
                                        path.addLine(to: point)
                                    }
                                }
                            }
                            .stroke(
                                Color.green.opacity(isBeatDetected ? 1.0 : 0.5),
                                lineWidth: 2
                            )
                        }

                        // Аудиометр (показывает уровень громкости)
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.yellow, Color.red]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 8, height: geometry.size.height * animatedLevel)
                                .cornerRadius(4)
                            Spacer()
                        }
                        .position(x: 20, y: geometry.size.height / 2)
                    }
                }
                .padding(.horizontal, 10)
                .onTapGesture {
                    withAnimation {
                        isFullscreen.toggle()
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if isFullscreen {
                                let deltaX = value.translation.width
                                let maxOffset = Double(beats.count - getVisibleBeatsCount(width: geometry.size.width))

                                // Переводим смещение жеста в смещение битов
                                let newOffset = scrollOffset - Double(deltaX) / 50.0
                                scrollOffset = max(0, min(maxOffset, newOffset))
                            }
                        }
                )
                .onChange(of: level) { oldLevel, newLevel in
                    withAnimation(.easeOut(duration: 0.1)) {
                        animatedLevel = newLevel
                    }

                    // Обновляем волну при изменении уровня звука
                    if showWaveform {
                        updateWavePoints(width: geometry.size.width, height: geometry.size.height, level: newLevel)
                    }
                }
                .onChange(of: currentBeatPosition) { oldPosition, newPosition in
                    // Автоматически прокручиваем при приближении к краю видимой области
                    if !isFullscreen {
                        let visibleBeats = Double(getVisibleBeatsCount(width: geometry.size.width))
                        let currentFirstBeat = Double(getFirstVisibleBeat())

                        if newPosition > currentFirstBeat + visibleBeats * 0.75 {
                            scrollOffset = max(0, Double(Int(newPosition) - Int(visibleBeats / 2)))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: isFullscreen ? nil : nil)
                .background(
                    isFullscreen ? Color.black.opacity(0.5) : Color.clear
                )
                .cornerRadius(10)
            }
        }
        .frame(height: isFullscreen ? UIScreen.main.bounds.height * 0.8 : nil)
        .position(x: UIScreen.main.bounds.width / 2, y: isFullscreen ? UIScreen.main.bounds.height / 2 : UIScreen.main.bounds.height / 2)
    }

    // Определяет, активен ли бит (находится ли он близко к текущей позиции)
    private func isBeatActive(_ beat: Double) -> Bool {
        return abs(beat - currentBeatPosition) < 0.1
    }

    // Получает позицию бита на экране
    private func getBeatPosition(beat: Double, width: CGFloat) -> CGFloat {
        let visibleBeatsCount = CGFloat(getVisibleBeatsCount(width: width))
        let firstVisibleBeat = CGFloat(getFirstVisibleBeat())
        let relativeBeatPosition = CGFloat(beat) - firstVisibleBeat

        return (relativeBeatPosition / visibleBeatsCount) * width
    }

    // Определяет, видимо ли попадание в текущем окне просмотра
    private func isHitVisible(_ time: Double) -> Bool {
        let firstVisibleBeat = Double(getFirstVisibleBeat())
        let visibleBeatsCount = Double(getVisibleBeatsCount(width: UIScreen.main.bounds.width))

        return time >= firstVisibleBeat && time <= (firstVisibleBeat + visibleBeatsCount)
    }

    // Возвращает цвет на основе точности попадания
    private func getAccuracyColor(_ accuracy: Double) -> Color {
        if accuracy <= 0.05 {
            return Color.green
        } else if accuracy <= 0.15 {
            return Color.blue
        } else {
            return Color.orange
        }
    }

    // Генерирует точки для аудиоволны
    private func generateWavePoints(width: CGFloat, height: CGFloat, level: Double) {
        wavePoints = []
        let centerY = height / 2
        let steps = 50

        for i in 0...steps {
            let x = (width / CGFloat(steps)) * CGFloat(i)
            let amplitude = CGFloat(level) * height * 0.3
            let y = centerY + CGFloat.random(in: -amplitude...amplitude)
            wavePoints.append(CGPoint(x: x, y: y))
        }
    }

    // Обновляет точки аудиоволны на основе уровня звука
    private func updateWavePoints(width: CGFloat, height: CGFloat, level: Double) {
        let centerY = height / 2
        let steps = 50

        var newPoints: [CGPoint] = []

        for i in 0...steps {
            let x = (width / CGFloat(steps)) * CGFloat(i)
            let amplitude = CGFloat(level) * height * 0.3

            // Создаем более реалистичную аудиоволну, зависящую от уровня звука
            let angle = Double(i) / Double(steps) * 2 * .pi * Double.random(in: 2...4)
            let randomFactor = Double.random(in: 0.7...1.3)
            let waveValue = sin(angle) * randomFactor

            let y = centerY + CGFloat(waveValue * Double(amplitude))
            newPoints.append(CGPoint(x: x, y: y))
        }

        withAnimation(.easeInOut(duration: 0.1)) {
            wavePoints = newPoints
        }
    }

    // Возвращает количество битов, которые могут поместиться в данной ширине
    private func getVisibleBeatsCount(width: CGFloat) -> Int {
        return 8 // Фиксированное количество для удобства чтения
    }

    // Возвращает индекс первого видимого бита на основе текущей позиции и смещения прокрутки
    private func getFirstVisibleBeat() -> Int {
        if isFullscreen {
            return max(1, Int(scrollOffset))
        } else {
            // В обычном режиме автоматически следуем за текущей позицией
            let currentBeat = Int(currentBeatPosition)
            let halfVisibleBeats = getVisibleBeatsCount(width: UIScreen.main.bounds.width) / 2

            return max(1, currentBeat - halfVisibleBeats)
        }
    }
}

struct AudioLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AudioLevelView(
            level: 0.7,
            isBeatDetected: true,
            showWaveform: true,
            beats: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
            currentBeatPosition: 3.5,
            userHits: [
                (time: 1.0, accuracy: 0.02),
                (time: 2.1, accuracy: 0.08),
                (time: 3.0, accuracy: 0.2)
            ]
        )
        .frame(height: 100)
        .padding()
        .background(Color.black.opacity(0.1))
    }
}