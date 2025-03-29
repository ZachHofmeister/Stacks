//
//  BudgetListView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

struct BudgetListView: View {
    @ObservedObject var budgetList = BudgetList.shared
    @StateObject private var budget = Budget()
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Welcome to Stacks!")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    EditButton()
                    Image(systemName: "plus")
                        .onTapGesture(count: 1, perform: budgetList.createBudget)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .environmentObject(budget)
    }
}

// Preview
#Preview {
    BudgetListView()
}
