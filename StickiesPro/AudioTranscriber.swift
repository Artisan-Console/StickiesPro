//
//  AudioTranscriber.swift
//  StickiesPro
//

import Combine
import Foundation
import Speech

@MainActor
final class AudioTranscriber: ObservableObject {
    enum State: Equatable {
        case idle
        case transcribing
        case unavailable
    }
    
    @Published private(set) var state: State = .idle
    
    func transcribe(_ attachment: StickyAudioAttachment) async -> String? {
        guard state != .transcribing else { return nil }
        state = .transcribing
        defer { state = .idle }
        
        do {
            let status = await requestAuthorization()
            guard status == .authorized else {
                state = .unavailable
                return nil
            }
            
            guard let recognizer = SFSpeechRecognizer(), recognizer.supportsOnDeviceRecognition else {
                state = .unavailable
                return nil
            }
            
            let url = try attachment.resolvedURL()
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            return try await recognitionResult(for: url, recognizer: recognizer)
        } catch {
            state = .unavailable
            return nil
        }
    }
    
    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    private func recognitionResult(for url: URL, recognizer: SFSpeechRecognizer) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.requiresOnDeviceRecognition = true
            
            var didResume = false
            recognizer.recognitionTask(with: request) { result, error in
                if let error, !didResume {
                    didResume = true
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result, result.isFinal, !didResume else { return }
                
                didResume = true
                let transcription = result.bestTranscription.formattedString
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: transcription.isEmpty ? nil : transcription)
            }
        }
    }
}
