//
//  StackEditorView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI
import SymbolPicker

// Editor for the details of the stack
struct StackEditorView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
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
                    TransactionView(transaction: bi)
                        .swipeActions(edge: .leading) {
                            Button("Clone") {
                                let copy = bi.copy() as! Transaction
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
        stack.budgetItems.insert(Transaction(), at: 0)
        budget.saveBudget()
    }
    private func cloneItem (from item: Transaction) {
        stack.budgetItems.insert(item, at: 0)
        budget.saveBudget()
    }
}

// Settings section for various stack types
struct StackSettingsView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
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

//Stack icon with colored background and symbol
struct StackIconButton : View {
    @ObservedObject var stack: Stack
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

//Settings unique to percent stacks
struct StackPercentSettings : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
    var body: some View {
        HStack {
            TextField("Percent", value: $stack.percent, formatter: budget.perFormatter) {
                _ in
                budget.saveBudget()
            }
            .modifier(BudgetTextfieldModifier())
//            .modifier(TextfieldSelectAllModifier())
            Text("\(budget.formatCurrency(from: stack.balance(budget: budget)))")
            .foregroundColor(stack.balance(budget: budget) >= 0 ? .green : .red)
            .bold()
        }
        .padding([.horizontal, .bottom])
    }
}

//Settings unique to reserved stacks
struct StackReservedSettings : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
    var body: some View {
        Text("\(budget.formatCurrency(from: stack.balance(budget: budget)))")
        .foregroundColor(stack.balance(budget: budget) >= 0 ? .green : .red)
        .bold()
        .padding([.top, .horizontal, .bottom])
    }
}

//Settings unique to accruing stacks
struct StackAccrueSettings : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
    var body: some View {
        HStack {
            TextField("Accruing Amount", value: $stack.accrue, formatter: budget.curFormatter) {
                _ in
                budget.saveBudget()
            }
            .modifier(BudgetTextfieldModifier())
//            .modifier(TextfieldSelectAllModifier())
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
//            .modifier(TextfieldSelectAllModifier())
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

//Settings display unique to the overflow stack
struct StackOverflowSettings : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
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

//Stats for a stack
struct StackDetails : View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
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

//Individual items formatted for the stack details
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
//
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

// Preview
struct StackEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BudgetView()
        }.environmentObject(Budget(
            balances: [Balance(of: 1500)],
            incomes: [Transaction(of: 2000)],
            stacks: [
                Stack(name: "test1", color: .red, type: .percent, percent: 0.1),
                Stack(name: "test1", color: .green, type: .accrue, accrue: 20),
                Stack(name: "test1", color: .blue, type: .reserved, budgetItems: [Transaction(of: 100)]),
                Stack(name: "test1", color: .yellow, type: .overflow)
            ]
        ))
    }
}
