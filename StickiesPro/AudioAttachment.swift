//
//  AudioAttachment.swift
//  StickiesPro
//

import AVFoundation
import Foundation
import UniformTypeIdentifiers

struct StickyAudioAttachment: Equatable {
    var filename: String
    var bookmarkData: Data
    var duration: Double?
    var transcription: String?
    
    static let supportedExtensions: Set<String> = ["m4a", "mp3", "wav"]
    static let droppedContentTypes = [UTType.fileURL.identifier]
    
    var durationText: String? {
        guard let duration, duration.isFinite, duration > 0 else { return nil }
        let totalSeconds = Int(duration.rounded())
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }
    
    var hasTranscription: Bool {
        guard let transcription else { return false }
        return !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func resolvedURL() throws -> URL {
        var isStale = false
        return try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }
    
    static func make(from url: URL) async throws -> StickyAudioAttachment {
        guard isSupportedAudioURL(url) else {
            throw AudioAttachmentError.unsupportedFile
        }
        
        let bookmarkData = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let duration = try await loadDuration(from: url)
        
        return StickyAudioAttachment(
            filename: url.lastPathComponent,
            bookmarkData: bookmarkData,
            duration: duration,
            transcription: nil
        )
    }
    
    static func isSupportedAudioURL(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    private static func loadDuration(from url: URL) async throws -> Double? {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)
        return seconds.isFinite && seconds > 0 ? seconds : nil
    }
}

enum AudioAttachmentError: LocalizedError {
    case unsupportedFile
    case unreadableDrop
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            "StickiesPro supports m4a, mp3, and wav attachments."
        case .unreadableDrop:
            "StickiesPro could not read that dropped audio file."
        }
    }
}
