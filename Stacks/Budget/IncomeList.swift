//
//  IncomeList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/27/25.
//

import SwiftUI

//TODO: can this be combined with TransactionList?
struct IncomeList: View {
    @EnvironmentObject var budget: Budget
        
    var body: some View {
        List {
            TransactionList(transactions: budget.incomes)
        }
        .navigationTitle("Income")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                EditButton()
                Image(systemName: "plus")
                    .onTapGesture(count: 1, perform: self.addIncome)
                    .foregroundColor(.accentColor)
            }
        }
        .onDisappear { budget.save() }
    }
    
    public func addIncome () {
        budget.incomes.list.insert(Transaction(), at: 0)
        budget.save()
    }
}

#Preview {
    let budget = Budget(incomes: Transactions([
        Transaction(of: 2000),
        Transaction(of: -3000),
        Transaction(of: 4567)
    ]))
    NavigationStack {
        IncomeList().environmentObject(budget)
    }
}
