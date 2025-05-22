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
                //Amount Textfield
                TextField(
                    "Amount",
                    value: $transaction.amount,
                    formatter: Formatters.curFormatter,
                    //save the budget when this field is deselected or view is closed
                    onEditingChanged: { isStart in
                        if (!isStart) { budget.save() }
                    }
                )
                    //save the budget whenever this value is edited
//                    .onChange(of: transaction.amount) { newValue in
//                        print(newValue)
//                        budget.save(change: false)
//                    }
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
                
                DatePicker("Date", selection: $transaction.date, displayedComponents: [.date])
                    .onChange(of: transaction.date) { _ in
                        budget.save()
                    }
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }.frame(height: 30)
            TextField(
                "Description",
                text: $transaction.desc,
                onEditingChanged: { isStart in
                    if (!isStart) { budget.save() }
                }
            )
        }
    }
}

// Preview
struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TransactionView(transaction: Transaction(of: 100, desc: "Payday" ))
            TransactionView(transaction: Transaction(of: -100, desc: "Groceries"))
        }
        .environmentObject(Budget())
        .previewLayout(.sizeThatFits)
    }
}
