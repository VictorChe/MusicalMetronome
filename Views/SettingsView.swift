
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: MetronomeModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedMode: MetronomeModel.TrainingMode = .tap
    @State private var tempo: Double = 90
    @State private var duration: Double = 20
    @State private var latencyCompensation: Double = 0
    @State private var showAdvancedSettings = false
    
    @State private var selectedPatterns: [MetronomeModel.RhythmPattern] = [.quarter, .eighthPair]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основные настройки")) {
                    VStack(alignment: .leading) {
                        Text("Режим: \(selectedMode.rawValue)")
                        Picker("Режим", selection: $selectedMode) {
                            ForEach(MetronomeModel.TrainingMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Темп: \(Int(tempo)) BPM")
                            Spacer()
                            Button(action: { playTempoExample() }) {
                                Image(systemName: "play.circle")
                            }
                        }
                        Slider(value: $tempo, in: 40...220, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Длительность: \(Int(duration)) секунд")
                        Slider(value: $duration, in: 10...60, step: 5)
                    }
                }
                
                Section(header: Text("Ритмические паттерны")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Выберите ритмические фигуры:")
                            .font(.subheadline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(MetronomeModel.RhythmPattern.allCases) { pattern in
                                PatternSelectionView(
                                    pattern: pattern,
                                    isSelected: selectedPatterns.contains(pattern),
                                    onToggle: { togglePattern(pattern) }
                                )
                            }
                        }
                    }
                }
                
                if selectedMode == .microphone {
                    Section(header: Text("Микрофон")) {
                        VStack(alignment: .leading) {
                            Text("Компенсация задержки: \(Int(latencyCompensation)) мс")
                            Slider(value: $latencyCompensation, in: -100...100, step: 5)
                            Text("Регулируйте если звуки распознаются раньше или позже")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(
                    header: Button(action: { showAdvancedSettings.toggle() }) {
                        HStack {
                            Text("Дополнительные настройки")
                            Spacer()
                            Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                        }
                    }
                ) {
                    if showAdvancedSettings {
                        Text("Будущие дополнительные настройки будут доступны здесь")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                // Загружаем текущие настройки из модели
                selectedMode = model.mode
                tempo = model.tempo
                duration = model.duration
                latencyCompensation = model.latencyCompensation
                selectedPatterns = model.selectedRhythmPatterns
            }
            .navigationTitle("Настройки")
            .navigationBarItems(
                leading: Button("Отмена") {
                    dismiss()
                },
                trailing: Button("Сохранить") {
                    saveSettings()
                    dismiss()
                }
            )
        }
    }
    
    private func saveSettings() {
        model.mode = selectedMode
        model.tempo = tempo
        model.duration = duration
        model.latencyCompensation = latencyCompensation
        model.selectedRhythmPatterns = selectedPatterns
        
        // Если выбрано меньше двух паттернов, добавляем базовый паттерн
        if model.selectedRhythmPatterns.isEmpty {
            model.selectedRhythmPatterns = [.quarter]
        }
    }
    
    private func togglePattern(_ pattern: MetronomeModel.RhythmPattern) {
        if let index = selectedPatterns.firstIndex(of: pattern) {
            selectedPatterns.remove(at: index)
        } else {
            selectedPatterns.append(pattern)
        }
    }
    
    private func playTempoExample() {
        // Здесь можно добавить воспроизведение примера текущего темпа
        print("Проигрывание примера темпа: \(Int(tempo)) BPM")
    }
}

struct PatternSelectionView: View {
    let pattern: MetronomeModel.RhythmPattern
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack {
                HStack(spacing: 2) {
                    ForEach(pattern.symbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 20))
                    }
                }
                
                Text(pattern.rawValue)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(minWidth: 80)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
