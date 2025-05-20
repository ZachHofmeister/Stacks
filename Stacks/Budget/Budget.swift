//
//  Budget.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/7/22.
//

import Foundation
import Combine

class Budget: ObservableObject, Codable, Identifiable {
    var id: UUID //should be const except loadPlist function needs to change
    @Published var name: String
    @Published var balances: [Balance]
    @Published var incomes: Transactions
    @Published var stacks: [Stack]
    
    var budgetUrl: URL {
        let docsURL = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
        let budgetListURL = docsURL.appendingPathComponent("BudgetList")
        let budgetUrl = budgetListURL.appendingPathComponent(id.uuidString).appendingPathExtension("plist")
        return budgetUrl
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
        for i in incomes.list {
            result += i.amount
        }
        return result
    }
    
    var ytdIncome: Double {
        var result = 0.0
        let yearStartComps = Calendar.current.dateComponents([.year], from: Date())
        let yearStart = Calendar.current.date(from: yearStartComps)!
        let yearNext = Calendar.current.date(byAdding: .year, value: 1, to: yearStart)!
        let thisYearRange = yearStart...yearNext
        
        for i in incomes.list {
            if thisYearRange.contains(i.date) {
                result += i.amount
            }
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
    
    var overflowStack: Stack? {
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
    
    init(id: UUID = UUID(), named name: String = "Budget", balances: [Balance] = [], incomes: Transactions = Transactions(), stacks: [Stack] = []) {
        self.id = id
        self.name = name
        self.balances = balances
        self.incomes = incomes
        self.stacks = stacks
    }
    
    // init from the URL of a plist file
    convenience init(from url: URL) {
        self.init()
        self.loadPlist(from: url)
    }
    
    // required to conform to Codable
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let incomeTransactions = (try? container.decode([Transaction].self, forKey: .incomes)) ?? []
        self.init(
            id: (try? container.decode(UUID.self, forKey: .id)) ?? UUID(),
            named: (try? container.decode(String.self, forKey: .name)) ?? "Budget",
            balances: (try? container.decode([Balance].self, forKey: .balances)) ?? [],
            incomes: Transactions(incomeTransactions),
            stacks: (try? container.decode([Stack].self, forKey: .stacks)) ?? []
        )
    }
    
    // required to conform to Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(balances, forKey: .balances)
        try container.encode(incomes.list, forKey: .incomes)
        try container.encode(stacks, forKey: .stacks)
    }
    
    // load budget from the URL of a plist file
    func loadPlist(from url: URL) {
        let plistDecoder = PropertyListDecoder()
        let retrievedBudget = try? Data(contentsOf: url)
        let decodedBudget = try? plistDecoder.decode(Budget.self, from: retrievedBudget!)
        self.id = decodedBudget?.id ?? UUID()
        self.name = decodedBudget?.name ?? "Budget"
        self.balances = decodedBudget?.balances ?? []
        self.incomes = decodedBudget?.incomes ?? Transactions()
        self.stacks = decodedBudget?.stacks ?? []
    }
    
    func save(change: Bool = true) {
        //Don't save to plist if running in preview mode
//        if (ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
            let plistEncoder = PropertyListEncoder()
            if let encodedBudget = try? plistEncoder.encode(self) {
                try? encodedBudget.write(to: budgetUrl, options: .noFileProtection)
            }
//        }
        
        if (change) { self.objectWillChange.send() }
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
        save()
    }
    
    
    
    func createStack(from stack: Stack = Stack()) {
        self.stacks.append(stack)
        self.save()
    }
    
    func moveStack (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            self.stacks.move(fromOffsets: offset, toOffset: index)
            self.save()
        }
    }
    
    func deleteStack (at offset: IndexSet) {
        self.stacks.remove(atOffsets: offset)
        self.save()
    }
}
