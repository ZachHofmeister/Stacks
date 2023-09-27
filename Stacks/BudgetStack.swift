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

class BudgetStack: ObservableObject, Identifiable, Codable, NSCopying {
    var id = UUID()
    @Published var name: String
    @Published var color: Color
    @Published var type: StackType
    @Published var percent: Double
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
    
    // All budget items that are increasing
    var totalAdded: Double {
        var total = 0.0
        for item in budgetItems where item.amount > 0 {
            total += item.amount;
        }
        return total
    }
    
    // All budget items that are spending
    var totalSpent: Double {
        var total = 0.0
        for item in budgetItems where item.amount < 0 {
            total += item.amount;
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
        accrue = 0.0
        accrueStart = Date()
        accrueFrequency = 1
        accruePeriod = .Days
        budgetItems = []
        icon = "dollarsign.circle"
    }
    
    init(name: String, color: Color, type: StackType, percent: Double, accrue: Double, accrueStart: Date, accrueFrequency: Int, accruePeriod: PeriodUnits, budgetItems: [BudgetItem], icon: String) {
        self.name = name
        self.color = color
        self.type = type
        self.percent = percent
        self.accrue = accrue
        self.accrueStart = accrueStart
        self.accrueFrequency = accrueFrequency
        self.accruePeriod = accruePeriod
        self.budgetItems = budgetItems
        self.icon = icon
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = BudgetStack(name: name, color: color, type: type, percent: percent, accrue: accrue, accrueStart: accrueStart, accrueFrequency: accrueFrequency, accruePeriod: accruePeriod, budgetItems: budgetItems, icon: icon)
        return copy
    }
    
    enum CodingKeys: CodingKey {
        case name, color, type, percent, accrue, accrueStart, accrueFrequency, accruePeriod, budgetItems, icon
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
        budgetItems = (try? container.decode([BudgetItem].self, forKey: .budgetItems)) ?? []
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
        try container.encode(budgetItems, forKey: .budgetItems)
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
        return baseAmount(budget: budget) + (type == .overflow ? 0 : totalBudgetItems)
    }
}

struct StackPreView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
//    @State private var editing = false
    
    var body: some View {
        NavigationLink(destination: StackEditorView(stack: stack)) {
            HStack {
                Image(systemName: stack.icon)
                    .padding(6)
                    .foregroundColor(Color.white)
                    .imageScale(.large)
                    .background(Circle().fill(stack.color))
                Text(stack.name)
//                Spacer()
                VStack {
                    HStack {
                        Spacer()
                        Text(budget.formatCurrency(from: stack.balance(budget: budget)))
                    }
                    HStack {
                        Spacer()
                        switch stack.type {
                        case .percent:
                            Text(budget.formatPercent(from: stack.percent))
                                .font(.footnote)
                        case .accrue:
                            Text("\(budget.formatCurrency(from: stack.accrue)) every \(stack.accrueFrequency) \(stack.accruePeriod.rawValue)")
                                .font(.footnote)
                        default:
                            Text(stack.type.rawValue)
                                .font(.footnote)
                        }
                    }
                }
            }
        }
    }
}

struct StackEditorView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    @State private var showDetails = false
    
    var body: some View {
        List {
            //Header, edit settings of stack
            Section {
                StackSettingsView(stack: stack)
            }
            .listRowInsets(EdgeInsets())
            
            
            //List of budget items
            if stack.type != .overflow {
                ForEach($stack.budgetItems, id: \.id) {
                    $bi in
                    BudgetItemEditor(budgetItem: bi)
                        .swipeActions(edge: .leading) {
                            Button("Clone") {
                                let copy = bi.copy() as! BudgetItem
                                self.cloneItem(from: copy)
                            }
                            .tint(.blue)
                        }
                }
                .onDelete(perform: self.deleteItem)
                .onMove(perform: self.moveItem)
                .cornerRadius(10)
                .padding([.horizontal])
            }
        } //main vstack
//        .environmentObject(budget)
        .navigationTitle("Stack Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if stack.type != .overflow {
                ToolbarItemGroup(placement: .bottomBar) {
                    EditButton()
                    Image(systemName: "plus")
                        .onTapGesture(count: 1, perform: self.addItem)
                        .foregroundColor(.accentColor)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                Menu(content: {
//
//                }) {
//                    Image(systemName: "ellipsis.circle")
//                }
                if (stack.type != .overflow) {
                    Button(action: {showDetails = true}) {
                        Label("Details", systemImage: "list.bullet.clipboard")
                    }
                    .popover(isPresented: $showDetails) {
                        GeometryReader { geo in
                            StackDetails(stack: stack)
                                .padding([.horizontal], geo.size.width/6)
                        }
                        .presentationDetents([.medium])
                        Button("Done") {
                            showDetails = false
                        }
                    }
                }
            }
        }
        
        
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
    private func cloneItem (from item: BudgetItem) {
        stack.budgetItems.insert(item, at: 0)
        budget.saveBudget()
    }
}

struct StackSettingsView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    
    var body: some View {
        VStack {
            StackIconButton(stack: stack)
            
            TextField("Stack Name", text: $stack.name) {
                _ in
                budget.saveBudget()
            }
            .modifier(BudgetTextfieldModifier())
            .padding([.top, .horizontal])
            
            Picker("Stack Type", selection: $stack.type) {
                Text("Percent").tag(StackType.percent)
                Text("Accrue").tag(StackType.accrue)
                Text("Reserve").tag(StackType.reserved)
                if !budget.hasOverflowStack || stack.type == .overflow {
                    Text("Overflow").tag(StackType.overflow)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if stack.type == .percent {
                StackPercentSettings(stack: stack)
            } else if stack.type == .reserved {
                StackReservedSettings(stack: stack)
            } else if stack.type == .accrue {
                StackAccrueSettings(stack: stack)
            } else if stack.type == .overflow {
                StackOverflowSettings(stack: stack)
            }
        } //VStack
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
        .onChange(of: stack.accruePeriod) {
            _ in
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

struct StackIconButton : View {
    @ObservedObject var stack: BudgetStack
    @State private var iconPickerOpen = false
    
    var body: some View {
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
    }
}

struct StackPercentSettings : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    
    var body: some View {
        HStack {
            TextField("Percent", value: $stack.percent, formatter: budget.perFormatter) {
                _ in
                budget.saveBudget()
            }
            .modifier(BudgetTextfieldModifier())
            .modifier(TextfieldSelectAllModifier())
            Text("\(budget.formatCurrency(from: stack.balance(budget: budget)))")
            .foregroundColor(stack.balance(budget: budget) >= 0 ? .green : .red)
            .bold()
        }
        .padding([.horizontal, .bottom])
    }
}

struct StackReservedSettings : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    
    var body: some View {
        Text("\(budget.formatCurrency(from: stack.balance(budget: budget)))")
        .foregroundColor(stack.balance(budget: budget) >= 0 ? .green : .red)
        .bold()
        .padding([.top, .horizontal, .bottom])
    }
}

struct StackAccrueSettings : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    
    var body: some View {
        HStack {
            TextField("Accruing Amount", value: $stack.accrue, formatter: budget.curFormatter) {
                _ in
                budget.saveBudget()
            }
            .modifier(BudgetTextfieldModifier())
            .modifier(TextfieldSelectAllModifier())
            Text("\(budget.formatCurrency(from: stack.balance(budget: budget)))")
            .foregroundColor(stack.balance(budget: budget) >= 0 ? .green : .red)
            .bold()
        }
        .padding(.horizontal)
        DatePicker("Starting", selection: $stack.accrueStart, displayedComponents: [.date])
        .datePickerStyle(.compact)
        .padding(.horizontal)
        HStack {
            Text("Accrue every")
            TextField("Accrue Frequency", value: $stack.accrueFrequency, format: .number)
            .modifier(BudgetTextfieldModifier())
            .modifier(TextfieldSelectAllModifier())
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
    }
}

struct StackOverflowSettings : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    
    var body: some View {
        Text("\(budget.formatCurrency(from: stack.balance(budget: budget)))")
        .foregroundColor(stack.balance(budget: budget) >= 0 ? .green : .red)
        .bold()
        .padding(.top)
        Text("Note: You can only have 1 overflow stack.")
        .font(.footnote)
        .padding([.top, .horizontal, .bottom])
    }
}

struct StackDetails : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: BudgetStack
    
    var body: some View {
        VStack {
            Text("Details")
            .font(.largeTitle).padding([.top])
            if (stack.type == .percent) {
                StackDetailItem(name: "Total Income", amount: budget.totalIncome)
                .padding([.top])
                StackDetailItem(name: "\(budget.formatPercent(from: stack.percent))", amount: stack.baseAmount(budget: budget))
                .padding([.top])
            }
            else if (stack.type == .accrue) {
                StackDetailItem(name: "Accrued", amount: stack.baseAmount(budget: budget))
                .padding([.top])
            }
            StackDetailItem(name: "Added", amount: stack.totalAdded)
            .padding([.top])
            StackDetailItem(name: "Spent", amount: stack.totalSpent)
            .padding([.top])
            StackDetailItem(name: "Balance", amount: stack.balance(budget: budget))
            .padding([.top, .bottom])
        }
    }
}

struct StackDetailItem : View {
    @EnvironmentObject var budget: Budget
    let name: String
    let amount: Double
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text("\(budget.formatCurrency(from: amount))")
            .foregroundColor(amount >= 0 ? .green : .red)
            .bold()
        }
    }
}

//Modifier for textfields in Stack
struct BudgetTextfieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height:36)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(10)
            .multilineTextAlignment(.center)
    }
}
