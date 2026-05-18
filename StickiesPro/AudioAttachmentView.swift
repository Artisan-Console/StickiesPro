//
//  AudioAttachmentView.swift
//  StickiesPro
//

import SwiftUI

struct AudioAttachmentView: View {
    enum Mode {
        case expanded
        case compact
    }
    
    @Binding var attachment: StickyAudioAttachment?
    @ObservedObject var player: AudioAttachmentPlayer
    let mode: Mode
    
    @StateObject private var transcriber = AudioTranscriber()
    
    var body: some View {
        if let attachment {
            switch mode {
            case .expanded:
                expandedView(for: attachment)
            case .compact:
                compactView(for: attachment)
            }
        }
    }
    
    private func expandedView(for attachment: StickyAudioAttachment) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            controlsRow(for: attachment, showsProgress: true, showsDuration: true, showsActions: true)
            
            if let transcription = attachment.transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(minHeight: 34)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.16))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
    }
    
    private func compactView(for attachment: StickyAudioAttachment) -> some View {
        controlsRow(for: attachment, showsProgress: player.isPlaying, showsDuration: false, showsActions: false)
            .frame(height: 22)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func controlsRow(
        for attachment: StickyAudioAttachment,
        showsProgress: Bool,
        showsDuration: Bool,
        showsActions: Bool
    ) -> some View {
        HStack(spacing: 7) {
            Button {
                player.togglePlayback()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 8, weight: .bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(player.isPlaying ? "Pause" : "Play")
            
            Text(attachment.filename)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: mode == .compact ? 92 : .infinity, alignment: .leading)
            
            if showsProgress {
                ProgressView(value: player.progress)
                    .progressViewStyle(.linear)
                    .controlSize(.mini)
                    .frame(width: mode == .compact ? 24 : 42)
                    .tint(.primary.opacity(0.35))
                    .opacity(0.65)
            }
            
            if showsDuration, let durationText = attachment.durationText {
                Text(durationText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            if showsActions {
                Spacer(minLength: 0)
                
                if !attachment.hasTranscription {
                    Button {
                        transcribe(attachment)
                    } label: {
                        Image(systemName: transcriber.state == .transcribing ? "ellipsis" : "text.quote")
                            .font(.system(size: 9, weight: .semibold))
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .disabled(transcriber.state == .transcribing)
                    .help("Transcribe on device")
                }
                
                Button {
                    self.attachment = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .help("Remove Audio")
            }
        }
        .foregroundStyle(.primary.opacity(0.72))
    }
    
    private func transcribe(_ attachment: StickyAudioAttachment) {
        Task {
            guard let transcription = await transcriber.transcribe(attachment) else { return }
            var updatedAttachment = attachment
            updatedAttachment.transcription = transcription
            self.attachment = updatedAttachment
        }
    }
}
