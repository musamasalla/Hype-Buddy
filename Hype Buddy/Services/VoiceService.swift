//
//  VoiceService.swift
//  Hype Buddy
//
//  Orchestrates TTS with Edge TTS primary, Native fallback
//

import Foundation
import AVFoundation
import Observation
import os.log

private let speechLogger = Logger(subsystem: "com.hypebuddy", category: "Speech")

@MainActor
@Observable
class VoiceService: NSObject, @preconcurrency AVSpeechSynthesizerDelegate {
    
    // MARK: - Properties
    
    private let edgeTTSService = EdgeTTSAPIService()
    private let synthesizer = AVSpeechSynthesizer()
    
    var isSpeaking = false
    var isUsingFallback = false
    var error: String?
    
    private var currentMascot: Mascot = .sparky
    
    override init() {
        super.init()
        synthesizer.delegate = self
        
        // Debug: Log TTS configuration
        if edgeTTSService.isConfigured {
            speechLogger.info("Edge TTS Server: Configured")
        } else {
            speechLogger.info("Edge TTS Server: Not configured, using Native TTS")
        }
    }
    
    // MARK: - Mascot Configuration
    
    func setMascot(_ mascot: Mascot) {
        currentMascot = mascot
        edgeTTSService.configureForMascot(mascot)
    }
    
    // MARK: - Speaking (Text to Speech)
    
    func speak(_ text: String) {
        // Stop any current speech
        stopSpeaking()
        
        // Strip emojis
        let sanitizedText = text.unicodeScalars
            .filter { !($0.properties.isEmoji && $0.properties.isEmojiPresentation) }
            .map(String.init)
            .joined()
        
        guard !sanitizedText.isEmpty else { return }
        
        // Try Edge TTS Server first (if configured)
        if edgeTTSService.isConfigured {
            speechLogger.debug("Attempting Edge TTS Server...")
            
            Task {
                do {
                    await MainActor.run { self.isSpeaking = true }
                    try await edgeTTSService.speak(sanitizedText)
                    
                    // Wait for completion
                    while edgeTTSService.isSpeaking {
                        try await Task.sleep(nanoseconds: 100_000_000)
                    }
                    await MainActor.run {
                        self.isSpeaking = false
                        self.isUsingFallback = false
                        self.deactivateAudioSession()
                    }
                } catch {
                    speechLogger.error("Edge TTS Server failed: \(error.localizedDescription)")
                    speechLogger.info("Falling back to Native TTS...")
                    await MainActor.run {
                        self.isUsingFallback = true
                        self.speakNative(sanitizedText)
                    }
                }
            }
        } else {
            // Use Native TTS directly
            speakNative(sanitizedText)
        }
    }
    
    // MARK: - Native TTS
    
    private func speakNative(_ text: String) {
        speechLogger.debug("Native TTS: Speaking '\(text.prefix(50))...'")
        
        // Configure Audio Session for Playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            speechLogger.error("Failed to configure audio session: \(error)")
        }
        
        // Create utterance with mascot-specific settings
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice
        utterance.rate = Float(currentMascot.voiceSpeed * 0.45)  // Adjust for native TTS
        utterance.pitchMultiplier = pitchForMascot
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    // MARK: - Voice Selection (Native TTS)
    
    private var preferredVoice: AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = voices.filter { $0.language == "en-US" }
        
        // Select voice based on mascot
        switch currentMascot {
        case .sparky:
            // Prefer male voice for Sparky
            if let male = englishVoices.first(where: { $0.gender == .male && $0.quality == .enhanced }) {
                return male
            }
            if let male = englishVoices.first(where: { $0.gender == .male }) {
                return male
            }
        case .boost, .pep:
            // Prefer female voice for Boost and Pep
            if let premium = englishVoices.first(where: { $0.quality == .premium && $0.gender == .female }) {
                return premium
            }
            if let enhanced = englishVoices.first(where: { $0.quality == .enhanced && $0.gender == .female }) {
                return enhanced
            }
            if let female = englishVoices.first(where: { $0.gender == .female }) {
                return female
            }
        }
        
        // Fallback
        return AVSpeechSynthesisVoice(language: "en-US")
    }
    
    private var pitchForMascot: Float {
        switch currentMascot {
        case .sparky: return 1.45  // High-pitched, bouncy child
        case .boost: return 1.5   // Bright, chirpy child
        case .pep: return 1.35    // Sweet, gentle child
        }
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        edgeTTSService.stop()
        isSpeaking = false
        deactivateAudioSession()
    }
    
    // MARK: - Audio Session Management
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            speechLogger.debug("Audio session deactivated — other apps restored")
        } catch {
            speechLogger.error("Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speechLogger.debug("Native TTS: Finished")
        isSpeaking = false
        deactivateAudioSession()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        speechLogger.debug("Native TTS: Started")
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        speechLogger.debug("Native TTS: Cancelled")
        isSpeaking = false
        deactivateAudioSession()
    }
}
