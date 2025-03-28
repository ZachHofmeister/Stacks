//
//  TransactionList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/27/25.
//

import SwiftUI

struct TransactionList: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
    var body: some View {
        ForEach($stack.transactions, id: \.id) {
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
        stack.transactions.remove(atOffsets: offset)
        budget.save()
    }
    private func moveItem (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            stack.transactions.move(fromOffsets: offset, toOffset: index)
            budget.save()
        }
    }
    private func cloneItem (from item: Transaction) {
        stack.transactions.insert(item, at: 0)
        budget.save()
    }
}

//#Preview {
//    let budget = Budget(stacks: [Stack()])
//    List {
//        TransactionList(stack: budget.stacks[0]).environmentObject(budget)
//    }
//}
