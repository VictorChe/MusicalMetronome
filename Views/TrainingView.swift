[Content same as provided in uploaded file, but with the following change applied:]

func setupAudioEngine() {
        if model.mode == .microphone {
            // Устанавливаем двустороннюю связь между моделью и аудио-движком
            model.audioEngine = audioEngine

            audioEngine.startMonitoring()
            audioEngine.onAudioDetected = { intensity in
                handleUserAction()
            }
        }
    }