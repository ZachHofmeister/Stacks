//
//  BalanceViewq.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

struct BalanceEditor: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var balance: Balance
    
    var body: some View {
        HStack {
            TextField("Name", text: $balance.name) {
                _ in
                budget.save()
                budget.objectWillChange.send()
            }
            .foregroundColor(.blue)
            TextField("Balance", value: $balance.balance, formatter: Formatters.curFormatter) {
                _ in
                budget.save()
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
