//
//  BudgetItem.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/8/22.
//

import Foundation
import SwiftUI

class BudgetItem: ObservableObject, Identifiable, Codable, Equatable {
    var id = UUID()
    @Published var amount: Double
    @Published var date: Date
    @Published var desc: String
    
    init(of amount: Double = 0.0, on date: Date = Date(), desc: String = "") {
        self.amount = amount
        self.date = date
        self.desc = desc
    }
    
    enum CodingKeys: CodingKey {
        case amount, date, desc
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = (try? container.decode(Double.self, forKey: .amount)) ?? 0.0
        date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        desc = (try? container.decode(String.self, forKey: .desc)) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encode(desc, forKey: .desc)
    }
    
    static func == (lhs: BudgetItem, rhs: BudgetItem) -> Bool {
        return lhs.id == rhs.id && lhs.amount == rhs.amount && lhs.date == rhs.date && lhs.desc == rhs.desc
    }
}

struct BudgetItemEditor: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var budgetItem: BudgetItem
    
    var body: some View {
        VStack {
            HStack {
                TextField("Amount", value: $budgetItem.amount, formatter: budget.curFormatter)
                    .foregroundColor(budgetItem.amount >= 0 ? .green : .red)
                    .modifier(TextfieldSelectAllModifier())
                DatePicker("Date", selection: $budgetItem.date, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }.frame(height: 30)
            .padding(1)
            TextField("Description", text: $budgetItem.desc).foregroundColor(.blue)
        }
        .onChange(of: budgetItem.amount) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: budgetItem.date) {
            _ in
            budget.saveBudget()
        }
        .onChange(of: budgetItem.desc) {
            _ in
            budget.saveBudget()
        }
    }
}


//struct IncomePreview: View {
//    @ObservedObject var income: BudgetItem
//
//    var body: some View {
//        VStack {
//            Text(income.name)
//            Text("Total Income: $\(income.totalIncome)")
//        }
//    }
//}
