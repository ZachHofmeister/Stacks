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
            ForEach($budget.incomes, id: \.id) {
                $income in
                TransactionView(transaction: income)
                    .swipeActions(edge: .leading) {
                        Button("Clone") {
                            self.cloneIncome(from: income)
                        }
                        .tint(.blue)
                    }
            }
            .onDelete(perform: self.deleteIncome)
            .onMove(perform: self.moveIncome)
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
    
    private func deleteIncome (at offset: IndexSet) {
        budget.incomes.remove(atOffsets: offset)
        budget.save()
    }
    private func moveIncome (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.incomes.move(fromOffsets: offset, toOffset: index)
            budget.save()
        }
    }
    public func addIncome () {
        budget.incomes.insert(Transaction(), at: 0)
        budget.save()
    }
    private func cloneIncome (from item: Transaction) {
        let copy = item.copy() as! Transaction
        budget.incomes.insert(copy, at: 0)
        budget.save()
    }
}
