//
//  Extensions.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/10/22.
//

import Foundation
import SwiftUI
import SymbolPicker

extension Color {
    static var random: Color {
        return Color(
            hue: Double.random(in: 0...1),
            saturation: 1.0,
            brightness: 1.0
        )
    }
    
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
}
