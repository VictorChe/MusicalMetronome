
import SwiftUI

struct ResultsView: View {
    @ObservedObject var model: MetronomeModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDetailedView = false
    @State private var isSpectrumFullscreen = false
    
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
                    let totalAttempts = model.perfectHits + model.goodHits + model.missedHits + model.extraHits
                    
                    Text("Всего битов: \(totalBeats)")
                    Text("Всего попыток: \(totalAttempts)")
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
                
                SpectrogramView(model: model)
                    .frame(height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .onTapGesture {
                        isSpectrumFullscreen = true
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
                Color.black.opacity(0.9)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ZoomableSpectrogramView(model: model)
                            .edgesIgnoringSafeArea(.all)
                    )
                    .onTapGesture(count: 2) { }  // Блокирует передачу двойного нажатия
                    .overlay(
                        Button {
                            isSpectrumFullscreen = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                        }
                        .padding(.top)
                        .padding(.trailing)
                        , alignment: .topTrailing
                    )
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
    }
    
    private func calculateBeatAccuracies() -> [Double] {
        // Здесь бы был настоящий расчет точности по тактам
        // Для демонстрации будем возвращать массив с случайными значениями
        let beatsPerMeasure = 4
        let numberOfMeasures = Int(ceil(Double(model.totalBeats) / Double(beatsPerMeasure)))
        
        var results: [Double] = []
        for _ in 0..<numberOfMeasures {
            // Случайные значения для демонстрации от 50 до 100%
            let randomAccuracy = Double.random(in: 50...100)
            results.append(randomAccuracy)
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
        ZStack {
            // Фон с сеткой
            GridBackground()
            
            // Метки для тактов и битов
            TimelineMarks(totalBeats: model.totalBeats, tempo: model.tempo)
            
            // Отображение кликов метронома
            MetronomeClicks(totalBeats: model.totalBeats)
            
            // Отображение попаданий пользователя
            UserHits(model: model)
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
                // Здесь в реальном приложении нужно использовать фактические данные
                // о времени попаданий пользователя, сейчас используем случайные данные
                ForEach(0..<30, id: \.self) { index in
                    let beatPosition = Double.random(in: 0...Double(model.totalBeats - 1))
                    let deviation = Double.random(in: -0.2...0.2)
                    let xPosition = (CGFloat(beatPosition) / CGFloat(model.totalBeats - 1)) * geometry.size.width
                    let yPosition = geometry.size.height / 2 + CGFloat(deviation * 50)
                    
                    let color: Color
                    if abs(deviation) < 0.05 {
                        color = .green  // Идеальное попадание
                    } else if abs(deviation) < 0.15 {
                        color = .blue   // Хорошее попадание
                    } else {
                        color = .orange // Неточное попадание
                    }
                    
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
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
