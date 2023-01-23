//
//  BudgetStack.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/8/22.
//

import Foundation
import SwiftUI
import SymbolPicker

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

class BudgetStack: ObservableObject, Identifiable, Codable {
    var id = UUID()
    @Published var name: String
    @Published var color: Color
    @Published var type: StackType
    @Published var percent: Double
    @Published var reserved: Double
    @Published var accrue: Double
    @Published var accrueStart: Date
    @Published var accrueFrequency: Int
    @Published var accruePeriod: PeriodUnits
    @Published var budgetItems: [BudgetItem]
    @Published var icon: String
    
    var totalBudgetItems: Double {
        var total = 0.0
        for item in budgetItems {
            total += item.amount
        }
        return total
    }
    
    var accruePeriodsElapsed: Int {
        let now = Date()
        let fromToComps = Calendar.current.dateComponents([accruePeriod.toCalComponent()], from: accrueStart, to: now)
        return 1 + accruePeriod.count(given: fromToComps) / (accrueFrequency == 0 ? 1 : accrueFrequency)
    }
    
    init() {
        name = "Stack"
        color = .random
        type = .percent
        percent = 0.0
        reserved = 0.0
        accrue = 0.0
        accrueStart = Date()
        accrueFrequency = 1
        accruePeriod = .Days
        budgetItems = []
        icon = "dollarsign.circle"
    }
    
    enum CodingKeys: CodingKey {
        case name, color, type, percent, reserved, accrue, accrueStart, accrueFrequency, accruePeriod, budgetItems, icon
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? "Stack"
        color = (try? container.decode(Color.self, forKey: .color)) ?? Color.random
        type = (try? container.decode(StackType.self, forKey: .type)) ?? StackType.percent
        percent = (try? container.decode(Double.self, forKey: .percent)) ?? 0.0
        reserved = (try? container.decode(Double.self, forKey: .reserved)) ?? 0.0
        accrue = (try? container.decode(Double.self, forKey: .accrue)) ?? 0.0
        accrueStart = (try? container.decode(Date.self, forKey: .accrueStart)) ?? Date()
        accrueFrequency = (try? container.decode(Int.self, forKey: .accrueFrequency)) ?? 1
        accruePeriod = (try? container.decode(PeriodUnits.self, forKey: .accruePeriod)) ?? PeriodUnits.Days
        budgetItems = (try? container.decode([BudgetItem].self, forKey: .budgetItems)) ?? []
        icon = (try? container.decode(String.self, forKey: .icon)) ?? "dollarsign.circle"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(type, forKey: .type)
        try container.encode(percent, forKey: .percent)
        try container.encode(reserved, forKey: .reserved)
        try container.encode(accrue, forKey: .accrue)
        try container.encode(accrueStart, forKey: .accrueStart)
        try container.encode(accrueFrequency, forKey: .accrueFrequency)
        try container.encode(accruePeriod, forKey: .accruePeriod)
        try container.encode(budgetItems, forKey: .budgetItems)
        try container.encode(icon, forKey: .icon)
    }
    
    func amount(budget: Budget) -> Double {
        switch type {
        case .percent:
            return budget.totalIncome * percent + totalBudgetItems
        case .reserved:
            return reserved
        case .accrue:
            return accrue * Double(accruePeriodsElapsed) + totalBudgetItems
        case .overflow:
            var reserved = 0.0
            for stack in budget.stacks {
                if stack.type != .overflow {
                    reserved += stack.amount(budget: budget)
                }
            }
            return budget.totalBalance - reserved
        }
    }
}

struct StackPreView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    @State private var editing = false
    
    var body: some View {
        VStack {
//            Button (action: {editing = true}) {
            NavigationLink(destination: StackEditorView(stack: stack)) {
                HStack {
                    VStack {
                        HStack {
                            Image(systemName: stack.icon)
                                .padding(6)
                                .foregroundColor(Color.white)
//                                .font(.system(size: 42))
                                .imageScale(.large)
                                .background(Circle().fill(stack.color)
                            )
                            Text(stack.name)
                            Spacer()
                        }
                    }
                    Spacer()
                    VStack {
                        HStack {
                            Spacer()
                            Text(budget.formatCurrency(from: stack.amount(budget: budget)))
                        }
                        HStack {
                            Spacer()
                            switch stack.type {
                            case .percent:
                                Text(budget.formatPercent(from: stack.percent)).font(.footnote)
                            case .accrue:
                                Text("\(budget.formatCurrency(from: stack.accrue)) every \(stack.accrueFrequency) \(stack.accruePeriod.rawValue)").font(.footnote)
                            default:
                                Text(stack.type.rawValue).font(.footnote)
                            }
                        }
                        
                    }
                }
            }
            .buttonStyle(BudgetStackButtonStyle(color: Color(.systemBackground)))
        }
    }
}

struct StackEditorView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    
    var body: some View {
        List {
            //Header, edit settings of stack
            Section {
                StackSettingsView(stack: stack)
            }
            .listRowInsets(EdgeInsets())
            
            
            //List of budget items
            if stack.type != .overflow {
                BudgetItemEditView(stack: stack)
                    .cornerRadius(10)
                    .padding([.horizontal])
            }
        } //main vstack
        .background(Color(.secondarySystemBackground))
        .navigationTitle("Stack Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StackSettingsView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    @State private var iconPickerOpen = false
    
    var body: some View {
        VStack {
            Button(action: {}, label: {
                Image(systemName: stack.icon)
                    .padding(16)
                    .foregroundColor(Color.white)
                    .font(.system(size: 36))
                    .background(Circle().fill(stack.color))
            })
            .onTapGesture() {
                iconPickerOpen = true
            }
                
            .sheet(isPresented: $iconPickerOpen) {
                ZStack {
                    SymbolPicker(symbol: $stack.icon)
                    VStack {
                        HStack {
                            Spacer()
                            ColorPicker("Stack Color", selection: $stack.color, supportsOpacity: false)
                                .labelsHidden()
                                .padding()
                        }
                        Spacer()
                    }
                }
            }
            .padding(.top)
            
            TextField("Stack Name", text: $stack.name)
                .modifier(BudgetTextfieldModifier(color: Color(.secondarySystemBackground)))
                .padding([.top, .horizontal])
            
            Picker("Stack Type", selection: $stack.type) {
                Text("Percent").tag(StackType.percent)
                Text("Reserve").tag(StackType.reserved)
                Text("Accrue").tag(StackType.accrue)
                if !budget.hasOverflowStack || stack.type == .overflow {
                    Text("Overflow").tag(StackType.overflow)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if stack.type == .percent {
                HStack {
                    TextField("Percent", value: $stack.percent, formatter: budget.perFormatter)
                        .modifier(BudgetTextfieldModifier(color: Color(.secondarySystemBackground)))
                    Text("\(budget.formatCurrency(from: stack.amount(budget: budget)))")
                        .foregroundColor(stack.amount(budget: budget) >= 0 ? .green : .red)
                        .bold()
                }
                .padding([.horizontal, .bottom])
            } else if stack.type == .reserved {
                HStack {
                    TextField("Reserved Amount", value: $stack.reserved, formatter: budget.curFormatter)
                        .modifier(BudgetTextfieldModifier(color: Color(.secondarySystemBackground)))
                    Text("\(budget.formatCurrency(from: stack.amount(budget: budget)))")
                        .foregroundColor(stack.amount(budget: budget) >= 0 ? .green : .red)
                        .bold()
                }
                .padding([.horizontal, .bottom])
            } else if stack.type == .accrue {
                HStack {
                    TextField("Accruing Amount", value: $stack.accrue, formatter: budget.curFormatter)
                        .modifier(BudgetTextfieldModifier(color: Color(.secondarySystemBackground)))
                    Text("\(budget.formatCurrency(from: stack.amount(budget: budget)))")
                        .foregroundColor(stack.amount(budget: budget) >= 0 ? .green : .red)
                        .bold()
                }
                .padding(.horizontal)
                DatePicker("Starting", selection: $stack.accrueStart, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                HStack {
                    Text("Accrue every")
                    TextField("Accrue Frequency", value: $stack.accrueFrequency, format: .number)
                        .modifier(BudgetTextfieldModifier(color: Color(.secondarySystemBackground)))
                    Picker("Accrue Period", selection: $stack.accruePeriod) {
                        Text("Days").tag(PeriodUnits.Days)
                        Text("Weeks").tag(PeriodUnits.Weeks)
                        Text("Months").tag(PeriodUnits.Months)
                        Text("Years").tag(PeriodUnits.Years)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .labelsHidden()
                }
                .padding([.horizontal, .bottom])
            } else if stack.type == .overflow {
                Text("\(budget.formatCurrency(from: stack.amount(budget: budget)))")
                    .foregroundColor(stack.amount(budget: budget) >= 0 ? .green : .red)
                    .bold()
                    .padding(.top)
                Text("Note: You can only have 1 overflow stack.")
                    .font(.footnote)
                    .padding([.top, .horizontal, .bottom])
            }
        } //second VStack
        .background(Color(.systemBackground))
        .cornerRadius(10)
//        .padding([.horizontal])
        .onChange(of: stack.name) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: stack.color) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: stack.type) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: stack.percent) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: stack.reserved) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: stack.accrue) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: stack.accrueStart) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: stack.accrueFrequency) {
            val in
            if (val <= 0) { stack.accrueFrequency = 1 }
            budget.saveBudget()
            budget.objectWillChange.send()
        }
        .onChange(of: stack.icon) {
            _ in
            budget.saveBudget()
            budget.objectWillChange.send()
        }
    }
}

struct BudgetItemEditView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    
    var body: some View {
        ForEach($stack.budgetItems, id: \.id) {
            $bi in
            BudgetItemEditor(budgetItem: bi)
        }
        .onDelete(perform: self.deleteItem)
        .onMove(perform: self.moveItem)
//        .toolbar {
//            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                EditButton()
//                    .padding()
//                Image(systemName: "plus")
//                    .onTapGesture(count: 1, perform: self.addItem)
//                    .foregroundColor(.accentColor)
//                    .padding()
//            }
//        }
    }
    
    private func deleteItem (at offset: IndexSet) {
        stack.budgetItems.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveItem (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            stack.budgetItems.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addItem () {
        stack.budgetItems.insert(BudgetItem(), at: 0)
        budget.saveBudget()
    }
}

struct BudgetStackButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .padding()
        .background(color.cornerRadius(10))
    }
}
