//
//  TransactionList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/27/25.
//

import SwiftUI

struct TransactionList: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var trans: TransactionArray
    
    var body: some View {
        ForEach($trans.array, id: \.id) {
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
        trans.array.remove(atOffsets: offset)
        budget.save()
    }
    private func moveItem (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            trans.array.move(fromOffsets: offset, toOffset: index)
            budget.save()
        }
    }
    private func cloneItem (from item: Transaction) {
        trans.array.insert(item, at: 0)
        budget.save()
    }
}

//#Preview {
//    let budget = Budget(stacks: [Stack()])
//    List {
//        TransactionList(stack: budget.stacks[0]).environmentObject(budget)
//    }
//}
