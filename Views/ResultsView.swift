import SwiftUI

struct ResultsView: View {
    @ObservedObject var model: MetronomeModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDetailedView = false
    @State private var isSpectrumFullscreen = false
    @State private var spectrogramScale: CGFloat = 1.0 // Added for zoom

    // Вычисляемое свойство для точности
    private var accuracy: Double {
        let totalBeats = model.totalBeats
        let totalAttempts = model.perfectHits + model.goodHits + model.missedHits + model.extraHits
        return totalBeats > 0 ? Double(model.perfectHits + model.goodHits) / Double(totalBeats + model.extraHits) * 100 : 0
    }

    var body: some View {
        if showDetailedView {
            detailedInfoView
        } else {
            summaryView
        }
    }

    var summaryView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Результаты тренировки")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 15) {
                    ResultRow(label: "Идеальные попадания", value: model.perfectHits, color: .green)
                    ResultRow(label: "Хорошие попадания", value: model.goodHits, color: .blue)
                    ResultRow(label: "Неточные попадания", value: model.missedHits, color: .orange)
                    ResultRow(label: "Пропущенные биты", value: model.skippedBeats, color: .red)
                    ResultRow(label: "Ноты мимо", value: model.extraHits, color: .purple)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 2)

                VStack(spacing: 10) {
                    let totalBeats = model.totalBeats
                    let attempts = model.perfectHits + model.goodHits + model.missedHits + model.extraHits

                    Text("Всего битов: \(totalBeats)")
                    Text("Всего попыток: \(attempts)")
                    Text(String(format: "Точность: %.1f%%", accuracy))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()

                VStack(spacing: 15) {
                    Button {
                        // Повторить тренировку с теми же настройками
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            model.startMetronome()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Повторить тренировку")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }

                    Button {
                        showDetailedView = true
                    } label: {
                        HStack {
                            Image(systemName: "waveform")
                            Text("Детальная информация")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(10)
                    }

                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Вернуться в меню")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }

    var detailedInfoView: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        showDetailedView = false
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                    }
                    Spacer()
                    Text("Детальный анализ").font(.headline)
                    Spacer()
                    Button {
                        isSpectrumFullscreen = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                }
                .padding()

                Text("Спектрограмма ритмической точности")
                    .font(.headline)
                    .padding(.bottom, 5)

                VStack {
                    SpectrogramView(model: model)
                        .frame(height: 200)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)

                    // Легенда спектрограммы
                    HStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                            Text("Метроном")
                                .font(.caption)
                        }

                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                            Text("Идеальные")
                                .font(.caption)
                        }

                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                            Text("Хорошие")
                                .font(.caption)
                        }

                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 10, height: 10)
                            Text("Неточные")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }


                VStack(alignment: .leading, spacing: 10) {
                    Text("Статистика по тактам:")
                        .font(.headline)
                        .padding(.top)

                    let beatAccuracies = calculateBeatAccuracies()
                    ForEach(Array(beatAccuracies.enumerated()), id: \.offset) { index, accuracy in
                        HStack {
                            Text("Такт \(index + 1):")
                            Spacer()
                            Text(String(format: "%.1f%%", accuracy))
                            CircularProgressView(progress: accuracy / 100)
                                .frame(width: 20, height: 20)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(5)
                    }
                }
                .padding()

                Spacer()

                Button {
                    showDetailedView = false
                } label: {
                    Text("Вернуться к результатам")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }

            if isSpectrumFullscreen {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    isSpectrumFullscreen = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                            }
                            .padding(.top)

                            ZoomableSpectrogramView(model: model)
                                .edgesIgnoringSafeArea(.all)
                                .background(Color.black)
                        }
                    )
                    .onTapGesture(count: 2) { }  // Блокирует передачу двойного нажатия
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
    }

    private func calculateBeatAccuracies() -> [Double] {
        let beatsPerMeasure = 4
        let numberOfMeasures = Int(ceil(Double(model.totalBeats) / Double(beatsPerMeasure)))

        var results: [Double] = []

        // Подсчитываем количество ударов в каждом такте
        for measure in 0..<numberOfMeasures {
            let startBeat = measure * beatsPerMeasure
            let endBeat = min(startBeat + beatsPerMeasure, model.totalBeats)

            // Проверяем, были ли удары в этом такте
            // Для этого используем идеальные, хорошие и неточные попадания
            let measureHits = min(model.perfectHits + model.goodHits + model.missedHits, endBeat - startBeat)
            let totalBeatsInMeasure = endBeat - startBeat

            // Если в такте не было ударов, ставим 0
            if measureHits == 0 {
                results.append(0.0)
            } else {
                // Считаем точность в процентах
                let accuracy = Double(measureHits) / Double(totalBeatsInMeasure) * 100
                results.append(accuracy)
            }
        }

        return results
    }
}

struct ResultRow: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct SpectrogramView: View {
    @ObservedObject var model: MetronomeModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Фон с сеткой тактов
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                            .frame(height: geometry.size.height / 4)
                    }
                }

                HStack(spacing: 0) {
                    ForEach(0..<model.totalBeats, id: \.self) { beatIndex in
                        Rectangle()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                            .frame(width: geometry.size.width / CGFloat(model.totalBeats))
                    }
                }

                // Аудио спектрограмма (упрощенная визуализация)
                Path { path in
                    // Создаем волнистую линию, имитирующую аудио волну
                    let stepX = geometry.size.width / CGFloat(50)
                    let midY = geometry.size.height / 2
                    var startPoint = CGPoint(x: 0, y: midY)

                    path.move(to: startPoint)

                    for i in 1...50 {
                        let x = CGFloat(i) * stepX
                        // Симуляция аудио волны с различной амплитудой, учитывая интенсивность ударов
                        let amplitude = CGFloat(15 + (sin(Double(i) * 0.5) * 10) + Double.random(in: -5...5))
                        let y = midY + (i % 2 == 0 ? amplitude : -amplitude)

                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Клики метронома
                ForEach(0..<model.totalBeats, id: \.self) { beatIndex in
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .position(
                            x: (CGFloat(beatIndex) + 0.5) * geometry.size.width / CGFloat(model.totalBeats),
                            y: geometry.size.height / 2
                        )
                        .overlay(
                            Text("\(beatIndex + 1)")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .offset(y: -15)
                        )
                }

                // Удары пользователя
                ForEach(model.userHits.indices, id: \.self) { index in
                    let hit = model.userHits[index]
                    let x = hit.beatPosition * geometry.size.width / CGFloat(model.totalBeats)
                    // Определяем цвет заранее
                    let hitColor: Color = hit.deviation <= 0.05 ? .green : 
                                       hit.deviation <= 0.15 ? .blue : .orange

                    Circle()
                        .fill(hitColor)
                        .frame(width: 10, height: 10)
                        .position(x: x, y: geometry.size.height / 2 + 20)
                        .overlay(
                            // Показываем отклонение в миллисекундах
                            Text("\(Int(hit.deviation * 1000))")
                                .font(.system(size: 8))
                                .foregroundColor(color)
                                .background(Color(UIColor.systemBackground).opacity(0.7))
                                .offset(y: 15)
                        )
                }
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
        }
    }
}

struct ZoomableSpectrogramView: View {
    @ObservedObject var model: MetronomeModel
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGPoint.zero
    @State private var lastOffset = CGPoint.zero

    var body: some View {
        SpectrogramView(model: model)
            .scaleEffect(scale)
            .offset(x: offset.x, y: offset.y)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = min(max(scale * delta, 1.0), 5.0)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if scale > 1.0 {
                            offset = CGPoint(
                                x: lastOffset.x + value.translation.width,
                                y: lastOffset.y + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation {
                    scale = 1.0
                    offset = .zero
                    lastOffset = .zero
                }
            }
    }
}

struct GridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Фоновый прямоугольник
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .border(Color.gray.opacity(0.2), width: 1)

                // Вертикальные линии (такты)
                ForEach(0..<11) { i in
                    Rectangle()
                        .fill(i % 4 == 0 ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2))
                        .frame(width: 1)
                        .position(x: geometry.size.width * CGFloat(i) / 10, y: geometry.size.height / 2)
                }

                // Горизонтальные линии (уровни точности)
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * CGFloat(i) / 4)
                }
            }
        }
    }
}

struct TimelineMarks: View {
    let totalBeats: Int
    let tempo: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Метки тактов
                ForEach(0..<(totalBeats / 4 + 1), id: \.self) { measureIndex in
                    let xPosition = (CGFloat(measureIndex * 4) / CGFloat(totalBeats)) * geometry.size.width

                    VStack {
                        Text("\(measureIndex + 1)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .position(x: xPosition, y: geometry.size.height / 2)
                }

                // Маркер темпа
                VStack {
                    Spacer()
                    Text("\(Int(tempo)) BPM")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}

struct MetronomeClicks: View {
    let totalBeats: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<totalBeats, id: \.self) { beatIndex in
                    let xPosition = (CGFloat(beatIndex) / CGFloat(totalBeats - 1)) * geometry.size.width

                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 2, height: 2)
                        .position(x: xPosition, y: geometry.size.height / 2)
                }
            }
        }
    }
}

struct UserHits: View {
    @ObservedObject var model: MetronomeModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Используем реальные данные из модели для отображения ударов
                // Это примерная визуализация, в реальном приложении нужно 
                // получать временные метки каждого удара

                // Идеальные попадания
                ForEach(0..<model.perfectHits, id: \.self) { index in
                    let beatIndex = min(model.totalBeats - 1, index * 4)
                    let xPosition = (CGFloat(beatIndex) / CGFloat(max(1, model.totalBeats - 1))) * geometry.size.width
                    let yPosition = geometry.size.height / 2 // Идеальное попадание - прямо по центру

                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .position(x: xPosition, y: yPosition)
                }

                // Хорошие попадания
                ForEach(0..<model.goodHits, id: \.self) { index in
                    let beatIndex = min(model.totalBeats - 1, index * 4 + 1)
                    let xPosition = (CGFloat(beatIndex) / CGFloat(max(1, model.totalBeats - 1))) * geometry.size.width
                    let deviation = 0.1 // Небольшое отклонение от центра
                    let yPosition = geometry.size.height / 2 + CGFloat(deviation * 50)

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(x: xPosition, y: yPosition)
                }

                // Неточные попадания
                ForEach(0..<model.missedHits, id: \.self) { index in
                    let beatIndex = min(model.totalBeats - 1, index * 4 + 2)
                    let xPosition = (CGFloat(beatIndex) / CGFloat(max(1, model.totalBeats - 1))) * geometry.size.width
                    let deviation = 0.25 // Большее отклонение от центра
                    let yPosition = geometry.size.height / 2 + CGFloat(deviation * 50)

                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .position(x: xPosition, y: yPosition)
                }

                // Мимо
                ForEach(0..<model.extraHits, id: \.self) { index in
                    let beatIndex = min(model.totalBeats - 1, index * 4 + 3)
                    let xPosition = (CGFloat(beatIndex) / CGFloat(max(1, model.totalBeats - 1))) * geometry.size.width
                    let deviation = 0.4 // Очень большое отклонение
                    let yPosition = geometry.size.height / 2 + CGFloat(deviation * 50)

                    Circle()
                        .fill(Color.purple)
                        .frame(width: 8, height: 8)
                        .position(x: xPosition, y: yPosition)
                }
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .opacity(0.3)
                .foregroundColor(.gray)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundColor(progress > 0.7 ? .green : progress > 0.4 ? .orange : .red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
    }
}