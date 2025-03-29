//
//  TransactionArray.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/28/25.
//

import Foundation

// Wrapper class to store array of Transactions, used for TransactionList to pass array by reference
class TransactionArray : ObservableObject, Codable {
    @Published var array: [Transaction]
    
    init(transactions: [Transaction] = []) {
        self.array = transactions
    }
    
    enum CodingKeys: CodingKey {
        case array
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        array = (try? container.decode([Transaction].self, forKey: .array)) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(array, forKey: .array)
    }
}
