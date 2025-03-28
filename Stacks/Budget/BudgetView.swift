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
    @State private var previewIncome: Double = 0.0
    
    var body: some View {
        List {
            Section {
                NavigationLink (destination: BalanceList()) {
                    Text("Total Balance: \(budget.formatCurrency(from: budget.totalBalance))")
                }
            }
            Section {
                NavigationLink (destination: IncomeList()) {
                    Text("Total Income: \(budget.formatCurrency(from: budget.totalIncome))")
                }
            }
            ForEach($budget.stacks, id: \.id) {
                $stack in
                StackPreView(stack: stack)
                    .swipeActions(edge: .leading) {
                        if (stack.type != .overflow) {
                            Button("Clone") {
                                let copy = stack.copy() as! Stack
                                self.cloneStack(from: copy)
                            }
                            .tint(.blue)
                        } else {
                            Button("Can't clone overflow") {
                            }
                            .tint(.gray)
                        }
                    }
            }
            .onDelete(perform: self.deleteStack)
            .onMove(perform: self.moveStack)
//            Section {
//                VStack {
//                    Text("Breakdown").font(.headline)
//                    TextField("Preview income", value: $previewIncome, formatter: budget.curFormatter)
//                    .foregroundColor(previewIncome >= 0 ? .green : .red)
//                }
//            }
        }
        .background(Color(.secondarySystemBackground))
        .navigationTitle(budget.name)
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
                    .onTapGesture(count: 1, perform: self.addStack)
                    .foregroundColor(.accentColor)
            }
        }
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
        .fileExporter(isPresented: $isExporting, document: budget.budgetFile, contentType: .json, defaultFilename: budget.name) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) {
            file in
            do {
                let fileUrl = try file.get()
                guard fileUrl.startAccessingSecurityScopedResource() else { return }
                if let data = try? Data(contentsOf: fileUrl) {
                    budget.importJson(from: data)
                }
                fileUrl.stopAccessingSecurityScopedResource()
            } catch {
                print ("error reading")
                print (error.localizedDescription)
            }
        }
    } //var body
    
    private func deleteStack (at offset: IndexSet) {
        budget.stacks.remove(atOffsets: offset)
        budget.save()
    }
    private func moveStack (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.stacks.move(fromOffsets: offset, toOffset: index)
            budget.save()
        }
    }
    private func addStack() {
        budget.stacks.append(Stack())
        budget.save()
    }
    private func cloneStack(from stack: Stack) {
        budget.stacks.append(stack)
        budget.save()
    }
}

// Preview
#Preview {
    NavigationStack {
        BudgetView()
    }.environmentObject(Budget(
        balances: [Balance(of: 1500)],
        incomes: [Transaction(of: 2000)],
        stacks: [
            Stack(name: "test1", color: .red, type: .percent, percent: 0.1),
            Stack(name: "test1", color: .green, type: .accrue, accrue: 20),
            Stack(name: "test1", color: .blue, type: .reserved, transactions: [Transaction(of: 100)]),
            Stack(name: "test1", color: .yellow, type: .overflow)
        ]
    ))
}
