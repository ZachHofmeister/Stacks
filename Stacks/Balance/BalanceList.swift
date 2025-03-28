//
//  BalanceList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/27/25.
//

import SwiftUI

struct BalanceList: View {
    @EnvironmentObject var budget: Budget
    
    var body: some View {
        List {
            ForEach($budget.balances, id: \.id) {
                $bal in
                BalanceEditor(balance: bal)
                    .swipeActions(edge: .leading) {
                        Button("Clone") {
                            let copy = bal.copy() as! Balance
                            self.cloneBalance(from: copy)
                        }
                        .tint(.blue)
                    }
            }
            .onDelete(perform: self.deleteBalance)
            .onMove(perform: self.moveBalance)
        }
        .navigationTitle("Balances")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                EditButton()
                Image(systemName: "plus")
                    .onTapGesture(count: 1, perform: self.addBalance)
                    .foregroundColor(.accentColor)
            }
        }
        .onDisappear { budget.save() }
    }
    
    private func deleteBalance (at offset: IndexSet) {
        budget.balances.remove(atOffsets: offset)
        budget.save()
    }
    private func moveBalance (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.balances.move(fromOffsets: offset, toOffset: index)
            budget.save()
        }
    }
    private func addBalance () {
        budget.balances.append(Balance())
        budget.save()
    }
    private func cloneBalance (from balance: Balance) {
        budget.balances.append(balance)
        budget.save()
    }
}
