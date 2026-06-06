//
//  StickyNoteView.swift
//  StickiesPro
//
//  Created by Michael Perez on 1/5/26.
//

import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

/// The individual sticky note view - this goes in each floating window
struct StickyNoteView: View {
    @Binding var content: String
    @Binding var color: Color
    @Binding var audioAttachment: StickyAudioAttachment?
    @ObservedObject var audioPlayer: AudioAttachmentPlayer
    let onClose: () -> Void
    let onNewSticky: () -> Void
    @ObservedObject var windowShadeController: WindowShadeController
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var isAudioDropTarget = false
    @State private var showsDeleteConfirmation = false
    @FocusState private var isFocused: Bool
    @Namespace private var morphNamespace
    @AppStorage(StickyTextStyle.fontSizeKey) private var noteFontSize = StickyTextStyle.defaultFontSize
    @AppStorage(StickyTextStyle.designKey) private var noteFontDesign = StickyTextStyle.defaultDesign
    
    private var title: String {
        StickyNoteTitle.make(from: content)
    }
    
    private var isExpanded: Bool {
        !windowShadeController.isShaded
    }
    
    private var surfaceCornerRadius: CGFloat {
        isExpanded ? 16 : 30
    }
    
    private var noteFont: Font {
        .system(size: noteFontSize, design: StickyTextStyle.fontDesign(for: noteFontDesign))
    }
    
    var body: some View {
        Group {
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    expandedToolbar
                    Divider()
                        .opacity(0.3)
                    noteBody
                    statusBar
                }
            } else {
                collapsedPill
            }
        }
        .matchedGeometryEffect(id: "stickySurface", in: morphNamespace)
        .glassEffect(.regular.tint(color.opacity(0.12)), in: .rect(cornerRadius: surfaceCornerRadius))
        .clipShape(RoundedRectangle(cornerRadius: surfaceCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: surfaceCornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(isHovered ? 0.35 : 0.18), lineWidth: 1)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isExpanded)
        .onHover { hovering in
            isHovered = hovering
        }
        .onExitCommand {
            endEditing()
        }
        .overlay {
            keyboardShortcutCommands
        }
        .overlay {
            if isAudioDropTarget {
                RoundedRectangle(cornerRadius: surfaceCornerRadius, style: .continuous)
                    .strokeBorder(.primary.opacity(0.22), lineWidth: 1)
                    .padding(3)
            }
        }
        .onDrop(
            of: StickyAudioAttachment.droppedContentTypes,
            isTargeted: $isAudioDropTarget,
            perform: handleAudioDrop
        )
        .alert("Delete this sticky?", isPresented: $showsDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onClose)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This note will be permanently removed.")
        }
    }
    
    private var expandedToolbar: some View {
        GlassEffectContainer {
            HStack(spacing: 8) {
                Button {
                    collapse()
                } label: {
                    toolbarIcon("chevron.up", size: 8)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("m", modifiers: .command)
                .help("Collapse")
                Button {
                    windowShadeController.zoom()
                } label: {
                    toolbarIcon("arrow.up.left.and.arrow.down.right", size: 8)
                }
                .buttonStyle(.plain)
                .help("Zoom")
                Spacer()
                Button(action: onNewSticky) {
                    toolbarIcon("plus", size: 9)
                }
                .buttonStyle(.plain)
                .help("New Sticky")
                Button(action: toggleEditing) {
                    toolbarIcon(isEditing ? "eye" : "info.circle", size: 11)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1 : 0.65)
                .help(isEditing ? "Preview" : "Edit")
                Button {
                    showsDeleteConfirmation = true
                } label: {
                    toolbarIcon("xmark", size: 9)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("w", modifiers: .command)
                .help("Delete")
            }
            .padding(.horizontal, 12)
        }
        .frame(height: windowShadeController.titleBarHeight)
        .onTapGesture(count: 2) {
            collapse()
        }
    }
    private var collapsedPill: some View {
        GlassEffectContainer {
            HStack(spacing: 8) {
                Button {
                    expand()
                } label: {
                    toolbarIcon("chevron.down", size: 8)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("m", modifiers: [.command, .shift])
                .help("Expand")
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: audioAttachment == nil ? .infinity : 72, alignment: .leading)
                AudioAttachmentView(
                    attachment: $audioAttachment,
                    player: audioPlayer,
                    mode: .compact
                )
                Spacer()
                Button(action: onNewSticky) {
                    toolbarIcon("plus", size: 9)
                }
                .buttonStyle(.plain)
                .help("New Sticky")
                Button {
                    showsDeleteConfirmation = true
                } label: {
                    toolbarIcon("xmark", size: 9)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("w", modifiers: .command)
                .help("Delete")
            }
            .padding(.horizontal, 12)
        }
        .frame(height: windowShadeController.titleBarHeight)
        .onTapGesture(count: 2) {
            expand()
        }
    }
    
    private var noteBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if isEditing {
                    TextEditor(text: $content)
                        .font(noteFont)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isFocused)
                        .frame(maxWidth: .infinity, minHeight: 200, alignment: .leading)
                } else if let attributedString = try? AttributedString(markdown: content) {
                    Text(attributedString)
                        .font(noteFont)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(content)
                        .font(noteFont)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                AudioAttachmentView(
                    attachment: $audioAttachment,
                    player: audioPlayer,
                    mode: .expanded
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private var statusBar: some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(content.split(separator: " ").count) words")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private var keyboardShortcutCommands: some View {
        Group {
            Button(action: beginEditing) {
                EmptyView()
            }
            .keyboardShortcut(.return, modifiers: .command)
            
            Button(action: endEditing) {
                EmptyView()
            }
            .keyboardShortcut(.cancelAction)
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }
    
    private func toolbarIcon(_ systemName: String, size: CGFloat) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(.primary.opacity(0.75))
            .frame(width: 18, height: 18)
            .background(Circle().fill(.white.opacity(0.28)))
    }
    
    private func toggleEditing() {
        isEditing.toggle()
        DispatchQueue.main.async {
            isFocused = isEditing
        }
    }
    
    private func beginEditing() {
        if !isExpanded {
            expand()
        }
        
        isEditing = true
        
        DispatchQueue.main.async {
            isFocused = true
        }
    }
    
    private func endEditing() {
        isFocused = false
        isEditing = false
    }
    
    private func collapse() {
        windowShadeController.collapse()
    }
    
    private func expand() {
        windowShadeController.expand()
    }
    
    private func handleAudioDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }) else {
            return false
        }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let url = droppedFileURL(from: item), StickyAudioAttachment.isSupportedAudioURL(url) else {
                return
            }
            
            Task {
                guard let attachment = try? await StickyAudioAttachment.make(from: url) else { return }
                await MainActor.run {
                    audioAttachment = attachment
                }
            }
        }
        
        return true
    }
    
    private func droppedFileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        
        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        
        if let string = item as? String {
            return URL(string: string)
        }
        
        return nil
    }
}

@MainActor
final class WindowShadeController: ObservableObject {
    @Published private(set) var isShaded = false
    let titleBarHeight: CGFloat = 34
    private let minimumExpandedHeight: CGFloat = 280
    weak var window: NSWindow? {
        didSet {
            guard let window, !isShaded else { return }
            recordExpandedGeometry(from: window)
        }
    }
    private var expandedFrame: NSRect?
    private var expandedMinSize: NSSize?
    private var expandedMaxSize: NSSize?
    private let shadeAnimation = Animation.spring(response: 0.38, dampingFraction: 0.72)
    private var windowMutationGeneration = 0
    func toggleShade() {
        if isShaded {
            expand()
        } else {
            collapse()
        }
    }
    func collapse() {
        guard let window, !isShaded else { return }
        shade(window: window)
    }
    func expand() {
        guard let window, isShaded else { return }
        restore(window: window)
    }
    func zoom() {
        guard let window, !isShaded else { return }
        scheduleWindowMutation { [weak window] in
            window?.performZoom(nil)
        }
    }
    private func shade(window: NSWindow) {
        let currentFrame = window.frame
        recordExpandedGeometry(from: window)
        let targetHeight = titleBarHeight
        let deltaHeight = currentFrame.height - targetHeight
        guard deltaHeight > 0 else { return }
        var shadedFrame = currentFrame
        shadedFrame.origin.y += deltaHeight
        shadedFrame.size.height = targetHeight
        withAnimation(shadeAnimation) {
            isShaded = true
        }
        scheduleWindowMutation { [weak window] in
            guard let window else { return }
            window.minSize = NSSize(width: 180, height: targetHeight)
            window.maxSize = NSSize(width: .greatestFiniteMagnitude, height: targetHeight)
            // Lock to borderless (no resizable) while shaded
            window.styleMask = .borderless
            window.setFrame(shadedFrame, display: true)
        }
    }
    private func restore(window: NSWindow) {
        // Expand in-place: use the current shaded position as the anchor.
        // expandedFrame is the size we recorded at collapse time, but we
        // position it at the current location so moving the pill doesn't
        // cause a jump.
        let savedSize = expandedFrame?.size ?? NSSize(width: 280, height: minimumExpandedHeight)
        let currentFrame = window.frame
        var targetFrame = NSRect(
            origin: currentFrame.origin,
            size: NSSize(
                width: max(savedSize.width, currentFrame.width),
                height: max(savedSize.height, minimumExpandedHeight)
            )
        )
        // If the saved frame was recorded, prefer its width
        if let expandedFrame {
            targetFrame.size.width = max(expandedFrame.width, currentFrame.width)
            targetFrame.size.height = max(expandedFrame.height, minimumExpandedHeight)
        }
        let expandedMinSize = expandedMinSize
        let expandedMaxSize = expandedMaxSize
        scheduleWindowMutation { [weak self, weak window] in
            guard let self, let window else { return }
            // Restore resizable borderless style
            window.styleMask = [.borderless, .resizable]
            window.maxSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            if let expandedMinSize {
                window.minSize = NSSize(
                    width: expandedMinSize.width,
                    height: max(expandedMinSize.height, self.minimumExpandedHeight)
                )
            }
            if let expandedMaxSize {
                if expandedMaxSize.height >= self.minimumExpandedHeight {
                    window.maxSize = expandedMaxSize
                } else {
                    window.maxSize = NSSize(width: expandedMaxSize.width, height: .greatestFiniteMagnitude)
                }
            }
            window.setFrame(targetFrame, display: true)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                withAnimation(shadeAnimation) {
                    self.isShaded = false
                }
            }
        }
    }
    private func recordExpandedGeometry(from window: NSWindow) {
        let currentFrame = window.frame
        guard currentFrame.height >= minimumExpandedHeight else { return }
        expandedFrame = currentFrame
        expandedMinSize = window.minSize
        expandedMaxSize = window.maxSize
    }
    private func normalizedExpandedFrame(_ frame: NSRect) -> NSRect {
        guard frame.height < minimumExpandedHeight else { return frame }
        var normalizedFrame = frame
        let heightDelta = minimumExpandedHeight - frame.height
        normalizedFrame.origin.y -= heightDelta
        normalizedFrame.size.height = minimumExpandedHeight
        return normalizedFrame
    }
    private func scheduleWindowMutation(_ mutation: @escaping @MainActor () -> Void) {
        windowMutationGeneration += 1
        let generation = windowMutationGeneration
        DispatchQueue.main.async { [weak self] in
            guard let self, self.windowMutationGeneration == generation else { return }
            mutation()
        }
    }
}
enum StickyNoteTitle {
    static func make(from content: String) -> String {
        let title = content
            .split(whereSeparator: \.isNewline)
            .map { cleanup(String($0)) }
            .first { !$0.isEmpty }
        return title ?? "New Sticky"
    }
    private static func cleanup(_ line: String) -> String {
        var cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
        while cleaned.first == "#" || cleaned.first == "-" || cleaned.first == "*" || cleaned.first == ">" {
            cleaned.removeFirst()
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


#Preview {
    StickyNoteView(
        content: .constant("# Preview Note\n\nThis is a **preview** of the sticky note.\n\n- Item 1\n- Item 2\n\n*More pro than ever!*"),
        color: .constant(.yellow),
        audioAttachment: .constant(nil),
        audioPlayer: AudioAttachmentPlayer(),
        onClose: {},
        onNewSticky: {},
        windowShadeController: WindowShadeController()
    )
    .frame(width: 280, height: 320)
}
