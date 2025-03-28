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
    @Published var incomes: [Transaction]
    @Published var stacks: [Stack]
        
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
    
    init(named name: String = "Budget", balances: [Balance] = [], incomes: [Transaction] = [], stacks: [Stack] = []) {
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
        self.incomes = (try? container.decode([Transaction].self, forKey: .incomes)) ?? []
        self.stacks = (try? container.decode([Stack].self, forKey: .stacks)) ?? []
        
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
    
    func save(change: Bool = true) {
        let plistEncoder = PropertyListEncoder()
        if let encodedBudget = try? plistEncoder.encode(self) {
            try? encodedBudget.write(to: budgetUrl, options: .noFileProtection)
        }
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
    
    func formatCurrency(from num: Double) -> String {
        return curFormatter.string(from: num as NSNumber) ?? "$format"
    }
    
    func formatPercent(from num: Double) -> String {
        return perFormatter.string(from: num as NSNumber) ?? "%format"
    }
}
