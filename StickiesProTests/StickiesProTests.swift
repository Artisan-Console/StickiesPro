//
//  StickiesProTests.swift
//  StickiesProTests
//
//  Created by Michael Perez on 1/5/26.
//

import Foundation
import Testing
@testable import StickiesPro

struct StickiesProTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func audioAttachmentSupportsOnlySmallLocalAudioFormats() {
        #expect(StickyAudioAttachment.isSupportedAudioURL(URL(fileURLWithPath: "/tmp/thought.m4a")))
        #expect(StickyAudioAttachment.isSupportedAudioURL(URL(fileURLWithPath: "/tmp/context.mp3")))
        #expect(StickyAudioAttachment.isSupportedAudioURL(URL(fileURLWithPath: "/tmp/room.wav")))
        #expect(!StickyAudioAttachment.isSupportedAudioURL(URL(fileURLWithPath: "/tmp/movie.mov")))
        #expect(!StickyAudioAttachment.isSupportedAudioURL(URL(fileURLWithPath: "/tmp/archive.aiff")))
    }
    
    @Test func audioAttachmentFormatsShortDurations() {
        let attachment = StickyAudioAttachment(
            filename: "memo.m4a",
            bookmarkData: Data(),
            duration: 83,
            transcription: nil
        )
        
        #expect(attachment.durationText == "1:23")
    }

}
