//
//  BalanceView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

struct BalanceView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var balance: Balance
    
    var body: some View {
        HStack {
            TextField("Name", text: $balance.name) { _ in
                budget.save()
            }
            TextField("Balance", value: $balance.balance, formatter: Formatters.curFormatter) { _ in
                budget.save()
            }
            .foregroundColor(balance.balance >= 0 ? .green : .red)
        }
    }
}

struct BalanceEditor_Previews: PreviewProvider {
    static var previews: some View {
        List {
            BalanceView(balance: Balance(named: "Bank", of: 100))
            BalanceView(balance: Balance(named: "Credit Card", of: -50))
        }
        .environmentObject(Budget())
        .previewLayout(.sizeThatFits)
    }
}
