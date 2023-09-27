//
//  Budget.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/7/22.
//

import Foundation
import SwiftUI
import Combine

class Budget: ObservableObject, Codable, Identifiable {
    var id: UUID //should be const except loadPlist function needs to change
    @Published var name: String
    @Published var balances: [Balance]
    @Published var incomes: [BudgetItem]
    @Published var stacks: [BudgetStack]
        
    let curFormatter: NumberFormatter = NumberFormatter()
    let perFormatter: NumberFormatter = NumberFormatter()
    
    var budgetUrl: URL {
        let docsUrl = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
        return docsUrl.appendingPathComponent(id.uuidString).appendingPathExtension("plist") //uses id as file name
    }
    
    //computed property is a BudgetFile object with latest budget data.
    var budgetFile: BudgetFile {
        return BudgetFile(data: exportJson())
    }
    
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
        case id, name, balances, incomes, stacks
    }
    
    init(named name: String = "Budget", balances: [Balance] = [], incomes: [BudgetItem] = [], stacks: [BudgetStack] = []) {
        self.id = UUID()
        self.name = name
        self.balances = balances
        self.incomes = incomes
        self.stacks = stacks
        
        initFormatters()
    }
    
    // init from the URL of a plist file
    init(from url: URL) {
        let plistDecoder = PropertyListDecoder()
        let retrievedBudget = try? Data(contentsOf: url)
        let decodedBudget = try? plistDecoder.decode(Budget.self, from: retrievedBudget!)
        self.id = decodedBudget?.id ?? UUID()
        self.name = decodedBudget?.name ?? "Budget"
        self.balances = decodedBudget?.balances ?? []
        self.incomes = decodedBudget?.incomes ?? []
        self.stacks = decodedBudget?.stacks ?? []
        
        initFormatters()
    }
    
    // required to conform to Codable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Budget"
        self.balances = (try? container.decode([Balance].self, forKey: .balances)) ?? []
        self.incomes = (try? container.decode([BudgetItem].self, forKey: .incomes)) ?? []
        self.stacks = (try? container.decode([BudgetStack].self, forKey: .stacks)) ?? []
        
        initFormatters()
    }
    // required to conform to Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(balances, forKey: .balances)
        try container.encode(incomes, forKey: .incomes)
        try container.encode(stacks, forKey: .stacks)
    }
    
    func initFormatters() {
        curFormatter.numberStyle = .currency
        curFormatter.maximumFractionDigits = 2
        curFormatter.isLenient = true
        
        perFormatter.numberStyle = .percent
        perFormatter.maximumFractionDigits = 1
        perFormatter.isLenient = true
    }
    
    // load data from the URL of a plist file
    func loadPlist(from url: URL) {
        let plistDecoder = PropertyListDecoder()
        let retrievedBudget = try? Data(contentsOf: url)
        let decodedBudget = try? plistDecoder.decode(Budget.self, from: retrievedBudget!)
        self.id = decodedBudget?.id ?? UUID()
        self.name = decodedBudget?.name ?? "Budget"
        self.balances = decodedBudget?.balances ?? []
        self.incomes = decodedBudget?.incomes ?? []
        self.stacks = decodedBudget?.stacks ?? []
    }
    
    func saveBudget() {
        let plistEncoder = PropertyListEncoder()
        if let encodedBudget = try? plistEncoder.encode(self) {
            try? encodedBudget.write(to: budgetUrl, options: .noFileProtection)
        }
    }
    
    // returns budget Data in json format
    func exportJson() -> Data {
        let jsonEncoder = JSONEncoder()
        // guard ensures encoding works
        guard let encodedBudget = try? jsonEncoder.encode(self) else { return Data() }
        return encodedBudget
    }
    
    // imports budget data from Data in json format
    func importJson(from data: Data) {
        let jsonDecoder = JSONDecoder()
        if let decodedBudget = try? jsonDecoder.decode(Budget.self, from: data) {
            self.name = decodedBudget.name
            self.balances = decodedBudget.balances
            self.incomes = decodedBudget.incomes
            self.stacks = decodedBudget.stacks
        }
        // save the newly imported data to the local serialized budget file
        saveBudget()
    }
    
    func formatCurrency(from num: Double) -> String {
        return curFormatter.string(from: num as NSNumber) ?? "$format"
    }
    
    func formatPercent(from num: Double) -> String {
        return perFormatter.string(from: num as NSNumber) ?? "%format"
    }
}

struct BudgetView: View {
    @EnvironmentObject var budget: Budget //= Budget()
    @State private var isRenaming = false
    @State private var isExporting = false
    @State private var isImporting = false
    
    var body: some View {
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
                    .swipeActions(edge: .leading) {
                        if (stack.type != .overflow) {
                            Button("Clone") {
                                let copy = stack.copy() as! BudgetStack
                                self.cloneStack(from: copy)
                            }
                            .tint(.blue)
                        } else {
                            Button("Can't clone overflow") {
                            }
                            .tint(.gray)
                        }
                    }
            }
            .onDelete(perform: self.deleteStack)
            .onMove(perform: self.moveStack)
        }
        .background(Color(.secondarySystemBackground))
        .navigationTitle(budget.name)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu(content: {
                    Button(action: {isRenaming = true}) {
                        Label("Rename", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    Button(action: {isExporting = true}) {
                        Label("Export to File", systemImage: "square.and.arrow.up")
                    }
                    Button(action: {isImporting = true}) {
                        Label("Import from File", systemImage: "square.and.arrow.down")
                    }
                }) {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                EditButton()
                Image(systemName: "plus")
                    .onTapGesture(count: 1, perform: self.addStack)
                    .foregroundColor(.accentColor)
            }
        }
        .alert("Rename Budget", isPresented: $isRenaming, actions: {
            let oldName = budget.name
            TextField("Budget name", text: $budget.name)
            Button("Done", action: {})
            Button("Cancel", role: .cancel, action: {budget.name = oldName})
        })
        .onChange(of: budget.name) {
            _ in
            budget.saveBudget()
//            budget.objectWillChange.send()
        }
        .fileExporter(isPresented: $isExporting, document: budget.budgetFile, contentType: .json, defaultFilename: budget.name) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) {
            file in
            do {
                let fileUrl = try file.get()
                guard fileUrl.startAccessingSecurityScopedResource() else { return }
                if let data = try? Data(contentsOf: fileUrl) {
                    budget.importJson(from: data)
                }
                fileUrl.stopAccessingSecurityScopedResource()
            } catch {
                print ("error reading")
                print (error.localizedDescription)
            }
        }
    } //var body
    
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
    private func addStack() {
        budget.stacks.append(BudgetStack())
        budget.saveBudget()
    }
    private func cloneStack(from stack: BudgetStack) {
        budget.stacks.append(stack)
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
                    .swipeActions(edge: .leading) {
                        Button("Clone") {
                            let copy = bal.copy() as! Balance
                            self.cloneBalance(from: copy)
                        }
                        .tint(.blue)
                    }
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
    private func cloneBalance (from balance: Balance) {
        budget.balances.append(balance)
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
                    .swipeActions(edge: .leading) {
                        Button("Clone") {
                            let copy = bi.copy() as! BudgetItem
                            self.cloneIncome(from: copy)
                        }
                        .tint(.blue)
                    }
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
    private func cloneIncome (from item: BudgetItem) {
        budget.incomes.insert(item, at: 0)
        budget.saveBudget()
    }
}

//Modifier for text field to make all text fields select all when tapped
struct TextfieldSelectAllModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectAll(self)
                }
            }
    }
}
