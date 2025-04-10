//
//  BudgetListView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI
import TellerKit

struct BudgetListView: View {
    @EnvironmentObject var budget: Budget
    @ObservedObject private var budgetList = BudgetList.shared
    
    var body: some View {
        List {
            ForEach(budgetList.urlList, id: \.self) {
                url in
                let budgetName = Budget(from: url).name
                NavigationLink(destination: BudgetView()
                    .onAppear{budget.loadPlist(from: url)}
                   //load onAppear: This is probably why there is a delay in name change, but not sure why it is just the name delayed
                ) {
                    Label(budgetName, systemImage: "book")
                }
                .swipeActions (edge: .trailing) {
                    Button(role: .destructive, action: {budgetList.deleteBudget(at: url)}) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: BankDataView()) {
                    Text("Banks")
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                EditButton()
                Label("Add Budget", systemImage: "plus")
                    .foregroundColor(.accentColor)
                    .onTapGesture(count: 1, perform: budgetList.createBudget)
                    .labelStyle(.titleAndIcon)
            }
        }
        .font(.system(size: 18))
    }
}

// Preview
#Preview {
    BudgetListView()
}
