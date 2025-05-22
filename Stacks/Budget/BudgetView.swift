//
//  BudgetView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/25/25.
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var budget: Budget
    @State private var isRenaming = false
    @State private var isExporting = false
    @State private var isImporting = false
//    @State private var previewIncome: Double = 0.0
    
    var body: some View {
        List {
            // Balance Section
            Section {
                NavigationLink (destination: BalanceList()) {
                    Text("Total Balance: \(Formatters.asCurrency(from: budget.totalBalance))")
                }
            }
            // Income Section
            Section {
                NavigationLink (destination: IncomeList()) {
                    Text("YTD Income: \(Formatters.asCurrency(from: budget.ytdIncome))")
                }
            }
            // List of Stacks
            ForEach($budget.stacks, id: \.id) {
                $stack in
                StackPreView(stack: stack)
                    .swipeActions(edge: .leading) {
                        if (stack.type != .overflow) {
                            Button("Clone") {
                                let copy = stack.copy() as! Stack
                                budget.createStack(from: copy)
                            }
                            .tint(.blue)
                        } else {
                            Button("Can't clone overflow") {
                            }
                            .tint(.gray)
                        }
                    }
            }
            .onDelete(perform: budget.deleteStack)
            .onMove(perform: budget.moveStack)
        }
        
        // Title
        .navigationTitle(budget.name)
        .navigationBarTitleDisplayMode(.large)
        
        // Toolbar
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu(content: {
                    Button(action: {isRenaming = true}) {
                        Label("Rename", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    Button(action: {isExporting = true}) {
                        Label("Export to File", systemImage: "square.and.arrow.up")
                    }
                    Button(action: {isImporting = true}) {
                        Label("Import from File", systemImage: "square.and.arrow.down")
                    }
                }) {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                EditButton()
                Image(systemName: "plus")
                    .onTapGesture(count: 1, perform: {budget.createStack()})
                    .foregroundColor(.accentColor)
            }
        }
        
        // Ellipsis menu: Rename
        .alert("Rename Budget", isPresented: $isRenaming, actions: {
            let oldName = budget.name
            TextField("Budget name", text: $budget.name)
            Button("Done", action: {})
            Button("Cancel", role: .cancel, action: {budget.name = oldName})
        })
        .onChange(of: budget.name) {
            _ in
            budget.save()
        }
        
        // Ellipsis menu: Export
        .fileExporter(isPresented: $isExporting, document: budget.budgetFile, contentType: .json, defaultFilename: budget.name) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        // Ellipsis menu: Import
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) {
            file in
            do {
                let fileUrl = try file.get()
                guard fileUrl.startAccessingSecurityScopedResource() else { return }
                if let data = try? Data(contentsOf: fileUrl) {
                    budget.importJson(from: data)
                }
                fileUrl.stopAccessingSecurityScopedResource()
            } catch let error {
                print ("error reading")
                print (error.localizedDescription)
            }
        }
    } //var body
}

// Preview
#Preview {
    let budget = Budget(
        balances: [Balance(of: 1500)],
        incomes: Transactions([Transaction(of: 2000)]),
        stacks: [
            Stack(name: "test1", color: .red, type: .percent, percent: 0.1),
            Stack(name: "test1", color: .green, type: .accrue, accrue: 20),
            Stack(name: "test1", color: .blue, type: .reserved, transactions: Transactions([
                Transaction(of: 100), Transaction(of: 100), Transaction(of: 100), Transaction(of: 100)
            ])),
//            Stack(name: "test1", color: .yellow, type: .overflow)
        ]);
    NavigationStack {
        BudgetView()
    }.environmentObject(budget)
}
