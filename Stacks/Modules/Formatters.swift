//
//  Formatters.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/30/25.
//

import Foundation

enum Formatters {
    static let curFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.isLenient = true
        return formatter
    }()
    
    static let perFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.isLenient = true
        return formatter
    }()
    
    static func asCurrency(from num: Double) -> String {
        return Formatters.curFormatter.string(from: num as NSNumber) ?? "$format"
    }
    
    static func asPercent(from num: Double) -> String {
        return Formatters.perFormatter.string(from: num as NSNumber) ?? "%format"
    }
}
