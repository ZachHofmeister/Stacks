//
//  StackPreView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

// How the stack appears in the budget stack list
struct StackPreView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
    var body: some View {
        NavigationLink(destination: StackEditorView(stack: stack)) {
            HStack {
                Image(systemName: stack.icon)
                    .padding(6)
                    .foregroundColor(Color.white)
                    .imageScale(.large)
                    .background(Circle().fill(stack.color))
                Text(stack.name)
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

// Preview
struct StackPreView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BudgetView()
        }.environmentObject(Budget(
            balances: [Balance(of: 1500)],
            incomes: [BudgetItem(of: 2000)],
            stacks: [
                Stack(name: "test1", color: .red, type: .percent, percent: 0.1),
                Stack(name: "test1", color: .green, type: .accrue, accrue: 20),
                Stack(name: "test1", color: .blue, type: .reserved, budgetItems: [BudgetItem(of: 100)]),
                Stack(name: "test1", color: .yellow, type: .overflow)
            ]
        ))
    }
}
