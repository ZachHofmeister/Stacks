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
        NavigationView {
            List {
                Section {
                    NavigationLink (destination: BalanceEditView()) {
                        Text("Total Balance: \(budget.formatCurrency(from: budget.totalBalance))")
                    }
                }
                Section {
                    NavigationLink (destination: IncomeEditView()) {
                        Text("Total Income: \(budget.formatCurrency(from: budget.totalIncome))")
                    }
                }
                ForEach($budget.stacks, id: \.id) {
                    $stack in
                    StackPreView(stack: stack)
                }
                .onDelete(perform: self.deleteStack)
                .onMove(perform: self.moveStack)
            }
            .background(Color(.secondarySystemBackground))
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    EditButton()
                    Image(systemName: "plus")
                        .onTapGesture(count: 1, perform: self.addStack)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .environmentObject(budget)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func deleteStack (at offset: IndexSet) {
        budget.stacks.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveStack (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.stacks.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addStack () {
        budget.stacks.append(BudgetStack())
        budget.saveBudget()
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
    }
    
    private func deleteBalance (at offset: IndexSet) {
        budget.balances.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveBalance (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.balances.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addBalance () {
        budget.balances.append(Balance())
        budget.saveBudget()
    }
}

//TODO: can this be combined with BudgetItemEditView?
struct IncomeEditView: View {
    @EnvironmentObject var budget: Budget
    
    var body: some View {
        List {
            ForEach($budget.incomes, id: \.id) {
                $bi in
                BudgetItemEditor(budgetItem: bi)
            }
            .onDelete(perform: self.deleteIncome)
            .onMove(perform: self.moveIncome)
        }
        .navigationTitle("Income")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                EditButton()
                Image(systemName: "plus")
                    .onTapGesture(count: 1, perform: self.addIncome)
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private func deleteIncome (at offset: IndexSet) {
        budget.incomes.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveIncome (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.incomes.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addIncome () {
        budget.incomes.insert(BudgetItem(), at: 0)
        budget.saveBudget()
    }
    private func duplicateIncome (at offset: IndexSet) {
        budget.incomes.insert(BudgetItem(), at: 0)
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
