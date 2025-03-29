//
//  IncomeList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/27/25.
//

import SwiftUI

//TODO: can this be combined with TransactionView?
struct IncomeList: View {
    @EnvironmentObject var budget: Budget
        
    var body: some View {
        List {
            TransactionList(trans: budget.incomes)
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
        budget.incomes.array.insert(Transaction(), at: 0)
        budget.save()
    }
}
