//
//  EdgeTTSAPIService.swift
//  Hype Buddy
//
//  Service to call self-hosted Edge TTS server (reused from Luna)
//

import Foundation
import AVFoundation
import Observation
import os.log

private let ttsLogger = Logger(subsystem: "com.hypebuddy", category: "TTS")

@Observable
class EdgeTTSAPIService: NSObject, AVAudioPlayerDelegate {
    
    // MARK: - Configuration
    
    private let serverURL: String
    private let apiKey: String
    
    // Voice options - Edge TTS neural voices
    // See: https://tts.travisvn.com for full list
    private var currentVoice = "en-US-GuyNeural"  // Energetic male voice for hype
    
    var isSpeaking: Bool = false
    private var audioPlayer: AVAudioPlayer?
    private var currentSpeed: Double = 1.15
    
    init(
        serverURL: String = Config.edgeTTSServerURL,
        apiKey: String = Config.edgeTTSAPIKey
    ) {
        self.serverURL = serverURL.isEmpty ? 
            (Bundle.main.object(forInfoDictionaryKey: "EDGE_TTS_SERVER_URL") as? String ?? "") : serverURL
        self.apiKey = apiKey
        super.init()
    }
    
    /// Check if the Edge TTS server is configured
    var isConfigured: Bool {
        !serverURL.isEmpty
    }
    
    // MARK: - Voice Configuration
    
    /// Set voice parameters for a specific mascot
    func configureForMascot(_ mascot: Mascot) {
        currentSpeed = mascot.voiceSpeed
        
        // Different voice styles for different mascots
        switch mascot {
        case .sparky:
            currentVoice = "en-US-GuyNeural"  // Energetic male
        case .boost:
            currentVoice = "en-US-JennyNeural"  // Inspiring female
        case .pep:
            currentVoice = "en-US-AvaNeural"  // Warm, friendly female
        }
    }
    
    // MARK: - TTS Generation
    
    func speak(_ text: String) async throws {
        guard isConfigured else {
            throw EdgeTTSError.serverNotConfigured
        }
        
        // Strip emojis
        let sanitizedText = text.unicodeScalars
            .filter { !($0.properties.isEmoji && $0.properties.isEmojiPresentation) }
            .map(String.init)
            .joined()
        
        guard !sanitizedText.isEmpty else { return }
        
        ttsLogger.debug("EdgeTTS API: Requesting speech for '\\(sanitizedText.prefix(50))...'")
        
        // Build request
        guard let url = URL(string: "\\(serverURL)/v1/audio/speech") else {
            throw EdgeTTSError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \\(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "model": "tts-1",
            "input": sanitizedText,
            "voice": currentVoice,
            "response_format": "mp3",
            "speed": currentSpeed
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EdgeTTSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            ttsLogger.error("EdgeTTS API Error (\\(httpResponse.statusCode)): \\(errorMessage)")
            throw EdgeTTSError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Play audio
        try await playAudio(data: data)
    }
    
    // MARK: - Audio Playback
    
    private func playAudio(data: Data) async throws {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
        
        // Create player
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        
        await MainActor.run { self.isSpeaking = true }
        
        guard let player = audioPlayer else {
            throw EdgeTTSError.playbackFailed
        }
        
        player.play()
        
        // Wait for playback to complete
        while player.isPlaying {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        
        await MainActor.run { self.isSpeaking = false }
    }
    
    func stop() {
        audioPlayer?.stop()
        isSpeaking = false
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

// MARK: - Errors

enum EdgeTTSError: LocalizedError {
    case serverNotConfigured
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .serverNotConfigured:
            return "Edge TTS server URL not configured"
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code, let message):
            return "Server error (\\(code)): \\(message)"
        case .playbackFailed:
            return "Audio playback failed"
        }
    }
}
