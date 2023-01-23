//
//  Balance.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/9/22.
//

import Foundation
import SwiftUI

class Balance: ObservableObject, Identifiable, Codable, Equatable {
    var id = UUID()
    @Published var name: String
    @Published var balance: Double
    
    init (named name: String = "", of balance: Double = 0.0) {
        self.name = name
        self.balance = balance
    }
    
    enum CodingKeys: CodingKey {
        case name, balance
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        balance = (try? container.decode(Double.self, forKey: .balance)) ?? 0.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(balance, forKey: .balance)
    }
    
    static func == (lhs: Balance, rhs: Balance) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.balance == rhs.balance
    }
}

struct BalanceEditor: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var balance: Balance
    
    var body: some View {
        HStack {
            TextField("Name", text: $balance.name).foregroundColor(.blue)
            TextField("Balance", value: $balance.balance, formatter: budget.curFormatter)
                .foregroundColor(.green)
        }
        .onChange(of: balance.name) {
            _ in
            budget.saveBudget()
        }
        .onChange(of: balance.balance) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
    }
}
