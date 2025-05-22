//
//  TransactionList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/27/25.
//

import SwiftUI

struct TransactionList: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var transactions: Transactions
    
    var body: some View {
        ForEach($transactions.list, id: \.id) {
            $tr in
            TransactionView(transaction: tr)
                .swipeActions(edge: .leading) {
                    Button("Clone") {
                        let copy = tr.copy() as! Transaction
                        self.cloneItem(from: copy)
                    }
                    .tint(.blue)
                }
        }
        .onDelete(perform: self.deleteItem)
        .onMove(perform: self.moveItem)
        .cornerRadius(10)
        .padding([.horizontal])
    }
    
    private func deleteItem (at offset: IndexSet) {
        transactions.list.remove(atOffsets: offset)
        budget.save()
    }
    private func moveItem (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            transactions.list.move(fromOffsets: offset, toOffset: index)
            budget.save()
        }
    }
    private func cloneItem (from item: Transaction) {
        transactions.list.insert(item, at: 0)
        budget.save()
    }
}

#Preview {
    let budget = Budget(
        balances: [Balance(of: 1500)],
        incomes: Transactions([Transaction(of: 2000)]),
        stacks: [
            Stack(name: "test1", color: .red, type: .percent, percent: 0.1, transactions: Transactions([
                Transaction(of: 100, on: Date.now, desc: "Hello"),
                Transaction(of: -50, on: Date.now, desc: "World"),
                Transaction(of: -50, on: Date.now, desc: "World"),
                Transaction(of: -50, on: Date.now, desc: "World"),
                Transaction(of: -50, on: Date.now, desc: "World")
            ])),
        ]);
    List {
        TransactionList(transactions: budget.stacks[0].transactions)
    }.environmentObject(budget)
}
