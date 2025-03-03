//
//  BudgetItem.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/8/22.
//

import Foundation
import SwiftUI

class BudgetItem: ObservableObject, Identifiable, Codable, Equatable, NSCopying {
    var id = UUID()
    @Published var amount: Double
    @Published var date: Date
    @Published var desc: String
    
    init(of amount: Double = 0.0, on date: Date = Date(), desc: String = "") {
        self.amount = amount
        self.date = date
        self.desc = desc
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = BudgetItem(of: amount, on: Date(), desc: desc)
        return copy
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

//struct BudgetItemList: View {
//    @EnvironmentObject var budget: Budget
//    var list: Binding<[BudgetItem]>
//    
//    var body: some View {
//            ForEach(list, id: \.id) {
//                $item in
//                BudgetItemEditor(budgetItem: item)
//                    .swipeActions(edge: .leading) {
//                        Button("Clone") {
//                            self.cloneIncome(from: item)
//                        }
//                        .tint(.blue)
//                    }
//            }
//            .onDelete(perform: self.deleteIncome)
//            .onMove(perform: self.moveIncome)
////        .toolbar {
////            ToolbarItemGroup(placement: .bottomBar) {
////                EditButton()
////                Image(systemName: "plus")
////                    .onTapGesture(count: 1, perform: self.addIncome)
////                    .foregroundColor(.accentColor)
////            }
////        }
//    }
//    
//    private func deleteIncome (at offset: IndexSet) {
//        list.wrappedValue.remove(atOffsets: offset)
//        budget.saveBudget()
//        budget.objectWillChange.send()
//    }
//    private func moveIncome (at offset: IndexSet, to index: Int) {
//        DispatchQueue.main.async {
//            list.wrappedValue.move(fromOffsets: offset, toOffset: index)
//            budget.saveBudget()
//        }
//    }
//    public func addIncome () {
//        list.wrappedValue.insert(BudgetItem(), at: 0)
//        budget.saveBudget()
//    }
//    private func cloneIncome (from item: BudgetItem) {
//        let copy = item.copy() as! BudgetItem
//        list.wrappedValue.insert(copy, at: 0)
//        budget.saveBudget()
//    }
//}

////List of budget items
//if stack.type != .overflow {
//    ForEach($stack.budgetItems, id: \.id) {
//        $bi in
//        BudgetItemEditor(budgetItem: bi)
//            .swipeActions(edge: .leading) {
//                Button("Clone") {
//                    let copy = bi.copy() as! BudgetItem
//                    self.cloneItem(from: copy)
//                }
//                .tint(.blue)
//            }
//    }
//    .onDelete(perform: self.deleteItem)
//    .onMove(perform: self.moveItem)
//    .cornerRadius(10)
//    .padding([.horizontal])
//}



// Preview
struct BudgetItemEditor_Previews: PreviewProvider {
    static var previews: some View {
        List {
            BudgetItemEditor(budgetItem: BudgetItem(of: 100, desc: "Payday" ))
            BudgetItemEditor(budgetItem: BudgetItem(of: -100, desc: "Groceries"))
        }
        .environmentObject(Budget())
        .previewLayout(.sizeThatFits)
    }
}
