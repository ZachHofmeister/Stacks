//
//  BudgetListView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

struct BudgetListView: View {
    @StateObject private var budgetList = BudgetList()
    @StateObject private var budget = Budget()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(budgetList.urlList, id: \.self) {
                    url in
                    // onAppear is used to change the Budget environment object
                    let budgetName = Budget(from: url).name
                    NavigationLink(destination: BudgetView()
                        .onAppear{budget.loadPlist(from: url)}
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Label("New Budget", systemImage: "plus")
                        .onTapGesture(count: 1, perform: budgetList.createBudget)
                        .foregroundColor(.accentColor)
                        .labelStyle(.titleAndIcon)
                        
                }
            }
        }
        .environmentObject(budget)
    }
}

// Preview
struct BudgetListView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetListView()
    }
}
