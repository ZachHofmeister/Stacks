//
//  Budget.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/7/22.
//

import Foundation
import SwiftUI

class Budget: ObservableObject, Codable {
    var name: String
    var desc: String
    @Published var balances: [Balance]
    @Published var incomes: [BudgetItem]
    @Published var stacks: [BudgetStack]
//    @Published var preview: Bool = false
    
    var budgetFileURL: URL = (
        FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
    ).appendingPathComponent("budget").appendingPathExtension("plist")
        
    let curFormatter: NumberFormatter = NumberFormatter()
    let perFormatter: NumberFormatter = NumberFormatter()
    
    var totalBalance: Double {
        var result = 0.0
        for b in balances {
            result += b.balance
        }
        return result
    }
    
    var totalIncome: Double {
        var result = 0.0
        for i in incomes {
            result += i.amount
        }
        return result
    }
    
    var hasOverflowStack: Bool {
        for stack in stacks {
            if stack.type == .overflow {
                return true
            }
        }
        return false
    }
    
    var overflowStack: BudgetStack? {
        for stack in stacks {
            if stack.type == .overflow {
                return stack
            }
        }
        return nil
    }
    
    enum CodingKeys: CodingKey {
        case name, desc, balances, incomes, stacks
    }
    
    init(named name: String = "Budget", desc: String = "", balances: [Balance] = [], incomes: [BudgetItem] = [], stacks: [BudgetStack] = []) {
        self.name = name
        self.desc = desc
        self.balances = balances
        self.incomes = incomes
        self.stacks = stacks
        
        initFormatters()
        loadBudget()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? "Budget"
        desc = (try? container.decode(String.self, forKey: .desc)) ?? ""
        balances = (try? container.decode([Balance].self, forKey: .balances)) ?? []
        incomes = (try? container.decode([BudgetItem].self, forKey: .incomes)) ?? []
        stacks = (try? container.decode([BudgetStack].self, forKey: .stacks)) ?? []
        
        initFormatters()
    }
    
    func initFormatters() {
        curFormatter.numberStyle = .currency
        curFormatter.maximumFractionDigits = 2
        curFormatter.isLenient = true
        
        perFormatter.numberStyle = .percent
        perFormatter.maximumFractionDigits = 1
        perFormatter.isLenient = true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(desc, forKey: .desc)
        try container.encode(balances, forKey: .balances)
        try container.encode(incomes, forKey: .incomes)
        try container.encode(stacks, forKey: .stacks)
    }
    
    func saveBudget() {
        let plistEncoder = PropertyListEncoder()
        if let encodedBudget = try? plistEncoder.encode(self) {
            try? encodedBudget.write(to: budgetFileURL, options: .noFileProtection)
        }
    }
    
    func loadBudget() {
        let plistDecoder = PropertyListDecoder()
        if let retrievedBudget = try? Data(contentsOf: budgetFileURL),
           let decodedBudget = try? plistDecoder.decode(Budget.self, from: retrievedBudget) {
            self.name = decodedBudget.name
            self.desc = decodedBudget.desc
            self.balances = decodedBudget.balances
            self.incomes = decodedBudget.incomes
            self.stacks = decodedBudget.stacks
        }
    }
    
    func formatCurrency(from num: Double) -> String {
        return curFormatter.string(from: num as NSNumber) ?? "$format"
    }
    
    func formatPercent(from num: Double) -> String {
        return perFormatter.string(from: num as NSNumber) ?? "%format"
    }
}

struct BudgetView: View {
    @StateObject var budget: Budget = Budget()
//    @State private var isExporting: Bool = false
//    @State private var isImporting: Bool = false
    
    var body: some View {
        GeometryReader {
            g in
            NavigationView {
                ScrollView {
                    VStack {
                        NavigationLink (destination: BalanceEditView()) {
                            HStack {
                                Text("Total Balance: \(budget.formatCurrency(from: budget.totalBalance))")
                                .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }.buttonStyle(.bordered)
                        NavigationLink (destination: IncomeEditView()) {
                            HStack {
                                Text("Total Income: \(budget.formatCurrency(from: budget.totalIncome))")
                                .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }.buttonStyle(.bordered)
                        StacksListView()
                    }
                    .navigationTitle(budget.name)
                    .toolbar {
//                        ToolbarItem(placement: .navigationBarTrailing) {
//                            if (budget.preview) {
//                                Button(action: {budget.preview.toggle()}) {
//                                    HStack {
//                                        Spacer()
//                                        Text("Preview").foregroundColor(Color.white)
//                                        Spacer()
//                                    }
//                                }
//                                .background(Color.blue.cornerRadius(10))
//                            } else {
//                                Button(action: {budget.preview.toggle()}) {
//                                    HStack {
//                                        Spacer()
//                                        Text("Preview")
//                                        Spacer()
//                                    }
//                                }
//                            }
//                        }
//                        ToolbarItem(placement: .navigationBarTrailing) {
//                            Button(action: {}) {
//                                Image(systemName: "square.and.arrow.down")
//                            }
//                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
            .environmentObject(budget)
        }
    }
}

struct BalanceEditView: View {
    @EnvironmentObject var budget: Budget
    
    var body: some View {
        List {
            ForEach($budget.balances, id: \.id) {
                $bal in
                BalanceEditor(balance: bal)
            }
            .onDelete(perform: self.deleteItem)
            .onMove(perform: self.moveItem)
        }
        .navigationTitle("Balances")
        .toolbar {
            ToolbarItem(placement: .principal) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "plus")
                .onTapGesture(count: 1, perform: self.addItem)
                .foregroundColor(.accentColor)
            }
        }
    }
    
    private func deleteItem (at offset: IndexSet) {
        budget.balances.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveItem (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.balances.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addItem () {
        budget.balances.append(Balance())
        budget.saveBudget()
    }
}

struct IncomeEditView: View {
    @EnvironmentObject var budget: Budget
    
    var body: some View {
        List {
            ForEach($budget.incomes, id: \.id) {
                $bi in
                BudgetItemEditor(budgetItem: bi)
            }
            .onDelete(perform: self.deleteItem)
            .onMove(perform: self.moveItem)
        }
        .navigationTitle("Income")
        .toolbar {
            ToolbarItem(placement: .principal) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "plus")
                .onTapGesture(count: 1, perform: self.addItem)
                .foregroundColor(.accentColor)
            }
        }
    }
    
    private func deleteItem (at offset: IndexSet) {
        budget.incomes.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveItem (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.incomes.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addItem () {
        budget.incomes.insert(BudgetItem(), at: 0)
        budget.saveBudget()
    }
}

struct StacksListView: View {
    @EnvironmentObject var budget: Budget
    
    var body: some View {
        ForEach($budget.stacks, id: \.id) {
            $stack in
            StackPreview(stack: stack)
        }
        NavigationLink(destination: StacksEditView()) {
            Text("Edit Stacks")
        }.buttonStyle(.bordered)
    }
}

struct StacksEditView: View {
    @EnvironmentObject var budget: Budget

    var body: some View {
        List {
            ForEach($budget.stacks, id: \.id) {
                $stack in
                StackPreview(stack: stack)
                    //.listRowBackground(stack.color)
            }
            .onDelete(perform: self.deleteItem)
            .onMove(perform: self.moveItem)
        }
        .navigationTitle("Stacks")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(systemName: "plus")
                .onTapGesture(count: 1, perform: self.addItem)
                .foregroundColor(.accentColor)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    private func deleteItem (at offset: IndexSet) {
        budget.stacks.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveItem (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.stacks.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addItem () {
        budget.stacks.append(BudgetStack())
        budget.saveBudget()
    }
}

struct BudgetTextfieldModifier: ViewModifier {
    public var color: Color
    
    func body(content: Content) -> some View {
        content
            .frame(height:36)
            .background(color)
            .cornerRadius(10)
            .multilineTextAlignment(.center)
//            .padding()
    }
}
