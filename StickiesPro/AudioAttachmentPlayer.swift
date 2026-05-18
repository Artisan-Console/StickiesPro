//
//  AudioAttachmentPlayer.swift
//  StickiesPro
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioAttachmentPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var progress = 0.0
    
    private var player: AVAudioPlayer?
    private var attachment: StickyAudioAttachment?
    private var securityScopedURL: URL?
    private var isAccessingSecurityScopedURL = false
    private var progressTimer: Timer?
    
    deinit {
        progressTimer?.invalidate()
        if isAccessingSecurityScopedURL {
            securityScopedURL?.stopAccessingSecurityScopedResource()
        }
    }
    
    func load(_ attachment: StickyAudioAttachment?) {
        if hasSameAudioFile(as: attachment) {
            self.attachment = attachment
            return
        }
        
        unload()
        self.attachment = attachment
        
        guard let attachment else { return }
        
        do {
            let url = try attachment.resolvedURL()
            isAccessingSecurityScopedURL = url.startAccessingSecurityScopedResource()
            securityScopedURL = url
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            self.player = player
            updateProgress()
        } catch {
            unload()
        }
    }
    
    func togglePlayback() {
        guard let player else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopProgressTimer()
        } else {
            player.play()
            isPlaying = true
            startProgressTimer()
        }
        
        updateProgress()
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        progress = 0
        stopProgressTimer()
    }
    
    private func unload() {
        stop()
        player = nil
        attachment = nil
        
        if isAccessingSecurityScopedURL {
            securityScopedURL?.stopAccessingSecurityScopedResource()
        }
        
        securityScopedURL = nil
        isAccessingSecurityScopedURL = false
    }
    
    private func hasSameAudioFile(as attachment: StickyAudioAttachment?) -> Bool {
        guard let currentAttachment = self.attachment, let attachment else {
            return self.attachment == nil && attachment == nil
        }
        
        return currentAttachment.filename == attachment.filename
            && currentAttachment.bookmarkData == attachment.bookmarkData
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        
        let timer = Timer(timeInterval: 0.33, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateProgress()
            }
        }
        
        progressTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player, player.duration > 0 else {
            progress = 0
            return
        }
        
        progress = min(max(player.currentTime / player.duration, 0), 1)
        
        if isPlaying && !player.isPlaying {
            isPlaying = false
            stopProgressTimer()
            progress = 1
        }
    }
}
