//
//  BudgetItemView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

struct BudgetItemView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var budgetItem: BudgetItem
    
    var body: some View {
        VStack {
            HStack {
                TextField("Amount", value: $budgetItem.amount, formatter: budget.curFormatter) {
                    _ in
                    budget.saveBudget()
                }
                    .foregroundColor(budgetItem.amount >= 0 ? .green : .red)
//                    .modifier(TextfieldSelectAllModifier())
                DatePicker("Date", selection: $budgetItem.date, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }.frame(height: 30)
            .padding(1)
            TextField("Description", text: $budgetItem.desc) {
                _ in
                budget.saveBudget()
            }
            .foregroundColor(.blue)
        }
        .onChange(of: budgetItem.date) {
            _ in
            budget.saveBudget()
        }
    }
}

// Preview
struct BudgetItemView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            BudgetItemView(budgetItem: BudgetItem(of: 100, desc: "Payday" ))
            BudgetItemView(budgetItem: BudgetItem(of: -100, desc: "Groceries"))
        }
        .environmentObject(Budget())
        .previewLayout(.sizeThatFits)
    }
}
