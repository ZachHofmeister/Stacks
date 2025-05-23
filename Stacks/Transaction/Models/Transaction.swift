//
//  Transaction.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/8/22.
//

import Foundation

class Transaction: ObservableObject, Identifiable, Codable, Equatable, NSCopying {
    var id = UUID()
    //Maybe: remove @Published here and other places it is not necessary
    @Published var amount: Double
    @Published var date: Date
    @Published var desc: String
    
    init(of amount: Double = 0.0, on date: Date = Date(), desc: String = "") {
        self.amount = amount
        self.date = date
        self.desc = desc
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Transaction(of: amount, on: Date(), desc: desc)
        return copy
    }
    
    enum CodingKeys: CodingKey {
        case amount, date, desc
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = (try? container.decode(Double.self, forKey: .amount)) ?? 0.0
        date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        desc = (try? container.decode(String.self, forKey: .desc)) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encode(desc, forKey: .desc)
    }
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id && lhs.amount == rhs.amount && lhs.date == rhs.date && lhs.desc == rhs.desc
    }
}
