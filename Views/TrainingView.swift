[Content same as provided in uploaded file, but with the following change applied:]

func handleUserAction() {
        let previousPerfectHits = model.perfectHits
        let previousGoodHits = model.goodHits
        let previousMissedHits = model.missedHits
        let previousExtraHits = model.extraHits

        if model.mode == .tap {
            model.handleTap()
        } else {
            // Добавим дополнительную отладочную информацию
            let intensity = audioEngine.audioLevel
            print("Обработка звука с интенсивностью: \(intensity)")
            model.handleAudioInput(intensity: intensity)
        }
    }