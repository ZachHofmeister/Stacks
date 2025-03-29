//
//  Stack.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/8/22.
//

import Foundation
import SwiftUI

enum StackType: String, CaseIterable, Identifiable, Codable {
    case percent, reserved, accrue, overflow
    var id: Self { self }
}

enum PeriodUnits: String, CaseIterable, Identifiable, Codable {
    case Days, Weeks, Months, Years
    var id: Self { self }
    
    func toCalComponent() -> Calendar.Component {
        switch self {
        case .Days: return Calendar.Component.day
        case .Weeks: return Calendar.Component.weekOfYear
        case .Months: return Calendar.Component.month
        case .Years: return Calendar.Component.year
        }
    }
    
    func count(given: DateComponents) -> Int {
        switch self {
        case .Days: return given.day ?? 0
        case .Weeks: return given.weekOfYear ?? 0
        case .Months: return given.month ?? 0
        case .Years: return given.year ?? 0
        }
    }
}

class Stack: ObservableObject, Identifiable, Codable, NSCopying {
    var id = UUID()
    @Published var name: String
    @Published var color: Color
    @Published var type: StackType
    @Published var percent: Double
    @Published var accrue: Double
    @Published var accrueStart: Date
    @Published var accrueFrequency: Int
    @Published var accruePeriod: PeriodUnits
    @Published var transactions: TransactionArray
    @Published var icon: String
    
    var totalTransactions: Double {
        var total = 0.0
        for item in transactions.array {
            total += item.amount
        }
        return total
    }
    
    // All budget items that are increasing
    var totalAdded: Double {
        var total = 0.0
        for item in transactions.array where item.amount > 0 {
            total += item.amount;
        }
        return total
    }
    
    // All budget items that are spending
    var totalSpent: Double {
        var total = 0.0
        for item in transactions.array where item.amount < 0 {
            total += item.amount;
        }
        return total
    }
    
    var accruePeriodsElapsed: Int {
        let now = Date()
        let fromToComps = Calendar.current.dateComponents([accruePeriod.toCalComponent()], from: accrueStart, to: now)
        return 1 + accruePeriod.count(given: fromToComps) / (accrueFrequency == 0 ? 1 : accrueFrequency)
    }
    
    init(
        name: String = "Stack",
        color: Color = .random,
        type: StackType = .percent,
        percent: Double = 0.0,
        accrue: Double = 0.0,
        accrueStart: Date = Date(),
        accrueFrequency: Int = 1,
        accruePeriod: PeriodUnits = .Days,
        transactions: TransactionArray = TransactionArray(),
        icon: String = "dollarsign.circle"
    ){
        self.name = name
        self.color = color
        self.type = type
        self.percent = percent
        self.accrue = accrue
        self.accrueStart = accrueStart
        self.accrueFrequency = accrueFrequency
        self.accruePeriod = accruePeriod
        self.transactions = transactions
        self.icon = icon
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Stack(name: name, color: color, type: type, accrue: accrue, accrueStart: accrueStart, accrueFrequency: accrueFrequency, accruePeriod: accruePeriod, transactions: transactions, icon: icon)
        return copy
    }
    
    enum CodingKeys: CodingKey {
        case name, color, type, percent, accrue, accrueStart, accrueFrequency, accruePeriod, transactions, icon
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? "Stack"
        color = (try? container.decode(Color.self, forKey: .color)) ?? Color.random
        type = (try? container.decode(StackType.self, forKey: .type)) ?? StackType.percent
        percent = (try? container.decode(Double.self, forKey: .percent)) ?? 0.0
        accrue = (try? container.decode(Double.self, forKey: .accrue)) ?? 0.0
        accrueStart = (try? container.decode(Date.self, forKey: .accrueStart)) ?? Date()
        accrueFrequency = (try? container.decode(Int.self, forKey: .accrueFrequency)) ?? 1
        accruePeriod = (try? container.decode(PeriodUnits.self, forKey: .accruePeriod)) ?? PeriodUnits.Days
        transactions = (try? container.decode(TransactionArray.self, forKey: .transactions)) ?? TransactionArray()
        icon = (try? container.decode(String.self, forKey: .icon)) ?? "dollarsign.circle"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(type, forKey: .type)
        try container.encode(percent, forKey: .percent)
        try container.encode(accrue, forKey: .accrue)
        try container.encode(accrueStart, forKey: .accrueStart)
        try container.encode(accrueFrequency, forKey: .accrueFrequency)
        try container.encode(accruePeriod, forKey: .accruePeriod)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(icon, forKey: .icon)
    }
    
    func baseAmount(budget: Budget) -> Double {
        switch type {
        case .percent:
            return budget.totalIncome * percent
        case .reserved:
            return 0
        case .accrue:
            return accrue * Double(accruePeriodsElapsed)
        case .overflow:
            var others = 0.0
            for stack in budget.stacks {
                if stack.type != .overflow {
                    others += stack.balance(budget: budget)
                }
            }
            return budget.totalBalance - others
        }
    }
    
    func balance(budget: Budget) -> Double {
        return baseAmount(budget: budget) + (type == .overflow ? 0 : totalTransactions)
    }
}
