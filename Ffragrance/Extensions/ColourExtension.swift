//
//  ColourExtension.swift
//  Ffragrance
//
//  Created by Ffinian Elliott on 13/01/2025.
//

import SwiftUI

extension Color {
    /// Initialize a `Color` from a hex string.
    init?(hex: String) {
        let r, g, b, a: CGFloat
        var hexColor = hex

        // Remove `#` if present
        if hex.hasPrefix("#") {
            hexColor = String(hex.dropFirst())
        }

        // Check if valid hex format
        guard let int = UInt64(hexColor, radix: 16) else {
            return nil
        }

        switch hexColor.count {
        case 6: // RGB (no alpha)
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
            a = 1.0
        case 8: // RGBA
            r = CGFloat((int >> 24) & 0xFF) / 255
            g = CGFloat((int >> 16) & 0xFF) / 255
            b = CGFloat((int >> 8) & 0xFF) / 255
            a = CGFloat(int & 0xFF) / 255
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    /// Convert a `Color` to a hex string.
    func toHex() -> String? {
        let components = self.cgColor?.components
        guard let components = components, components.count >= 3 else {
            return nil
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        let a = components.count >= 4 ? Int(components[3] * 255.0) : 255

        if a < 255 {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}
