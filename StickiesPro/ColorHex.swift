//
//  ColorHex.swift
//  StickiesPro
//

import SwiftUI
import AppKit

enum StickyColorCodec {
    static let fallbackHex = "#FFFF00"
    
    static func hex(from color: Color) -> String {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? .systemYellow
        let red = Int((nsColor.redComponent * 255).rounded())
        let green = Int((nsColor.greenComponent * 255).rounded())
        let blue = Int((nsColor.blueComponent * 255).rounded())
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    static func color(from hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
            return .yellow
        }
        
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}
