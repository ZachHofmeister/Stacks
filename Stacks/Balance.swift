//
//  Balance.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/9/22.
//

import Foundation
import SwiftUI

class Balance: ObservableObject, Identifiable, Codable, Equatable, NSCopying {
    var id = UUID()
    @Published var name: String
    @Published var balance: Double
    
    init (named name: String = "", of balance: Double = 0.0) {
        self.name = name
        self.balance = balance
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Balance(named: name, of: balance)
        return copy
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
            TextField("Name", text: $balance.name) {
                _ in
                budget.saveBudget()
                budget.objectWillChange.send()
            }
            .foregroundColor(.blue)
            TextField("Balance", value: $balance.balance, formatter: budget.curFormatter) {
                _ in
                budget.saveBudget()
                budget.objectWillChange.send()
            }
            .foregroundColor(balance.balance >= 0 ? .green : .red)
//            .modifier(TextfieldSelectAllModifier())
        }
    }
}

struct BalanceEditor_Previews: PreviewProvider {
    static var previews: some View {
        List {
            BalanceEditor(balance: Balance(named: "Bank", of: 100))
            BalanceEditor(balance: Balance(named: "Credit Card", of: -50))
        }
        .environmentObject(Budget())
        .previewLayout(.sizeThatFits)
    }
}
