//
//  ColorExt.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/10/22.
//

import SwiftUI

extension Color: Codable {
    //Return any random color
    static var random: Color {
        return Color(
            hue: Double.random(in: 0...1),
            saturation: 1.0,
            brightness: 1.0
        )
    }
    
    //Return any random system color
    static var randomSystem: Color {
        switch Int.random(in: 0...12) {
        case 0: return Color.yellow
        case 1: return Color.blue
        case 2: return Color.red
        case 3: return Color.green
        case 4: return Color.brown
        case 5: return Color.cyan
        case 6: return Color.gray
        case 7: return Color.indigo
        case 8: return Color.mint
        case 9: return Color.orange
        case 10: return Color.pink
        case 11: return Color.purple
        default: return Color.teal
        }
    }
    
    // The following is from ColorCodable.swift by Peter Friese
    // https://gist.github.com/peterfriese/bb2fc5df202f6a15cc807bd87ff15193
    // Inspired by https://cocoacasts.com/from-hex-to-uicolor-and-back-in-swift
    // Make Color codable. This includes support for transparency.
    // See https://www.digitalocean.com/community/tutorials/css-hex-code-colors-alpha-values
    init(hex: String) {
        let rgba = hex.toRGBA()
        
        self.init(.sRGB,
                  red: Double(rgba.r),
                  green: Double(rgba.g),
                  blue: Double(rgba.b),
                  opacity: Double(rgba.alpha))
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        
        self.init(hex: hex)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(toHex)
    }
    
    var toHex: String? {
        return toHex()
    }
    
    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX",
                          lroundf(r * 255),
                          lroundf(g * 255),
                          lroundf(b * 255),
                          lroundf(a * 255))
        }
        else {
            return String(format: "%02lX%02lX%02lX",
                          lroundf(r * 255),
                          lroundf(g * 255),
                          lroundf(b * 255))
        }
    }
}

