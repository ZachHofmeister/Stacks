//
//  TransactionView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

struct TransactionView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var transaction: Transaction
    
    var body: some View {
        VStack {
            HStack {
                TextField("Amount", value: $transaction.amount, formatter: budget.curFormatter) {
                    _ in
                    budget.saveBudget()
                }
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
//                    .modifier(TextfieldSelectAllModifier())
                DatePicker("Date", selection: $transaction.date, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }.frame(height: 30)
            .padding(1)
            TextField("Description", text: $transaction.desc) {
                _ in
                budget.saveBudget()
            }
            .foregroundColor(.blue)
        }
        .onChange(of: transaction.date) {
            _ in
            budget.saveBudget()
        }
    }
}

// Preview
struct BudgetItemView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TransactionView(transaction: Transaction(of: 100, desc: "Payday" ))
            TransactionView(transaction: Transaction(of: -100, desc: "Groceries"))
        }
        .environmentObject(Budget())
        .previewLayout(.sizeThatFits)
    }
}
