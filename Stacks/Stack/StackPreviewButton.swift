//
//  StackPreviewButton.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

// How the stack appears in the budget stack list
struct StackPreviewButton: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject var stack: Stack
    
    var body: some View {
        NavigationLink(destination: StackView(stack: stack)) {
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
                        Text(Formatters.asCurrency(from: stack.balance(budget: budget)))
                    }
                    HStack {
                        Spacer()
                        switch stack.type {
                        case .percent:
                            Text(Formatters.asPercent(from: stack.percent))
                                .font(.footnote)
                        case .accrue:
                            Text("\(Formatters.asCurrency(from: stack.accrue)) every \(stack.accrueFrequency) \(stack.accruePeriod.rawValue)")
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
#Preview {
    let budget = Budget(
        balances: [Balance(of: 1500)],
        incomes: Transactions([Transaction(of: 2000)]),
        stacks: [
            Stack(name: "test1", color: .red, type: .percent, percent: 0.1),
            Stack(name: "test1", color: .green, type: .accrue, accrue: 20),
            Stack(name: "test1", color: .blue, type: .reserved, transactions: Transactions([Transaction(of: 100)])),
//            Stack(name: "test1", color: .yellow, type: .overflow)
        ]);
    NavigationStack {
        BudgetView()
    }.environmentObject(budget)
}
