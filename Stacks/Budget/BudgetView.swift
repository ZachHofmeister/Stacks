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
                NavigationLink (destination: BalanceEditView()) {
                    Text("Total Balance: \(budget.formatCurrency(from: budget.totalBalance))")
                }
            }
            Section {
                NavigationLink (destination: IncomeEditView()) {
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
            budget.saveBudget()
//            budget.objectWillChange.send()
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
        budget.saveBudget()
    }
    private func moveStack (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.stacks.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addStack() {
        budget.stacks.append(Stack())
        budget.saveBudget()
    }
    private func cloneStack(from stack: Stack) {
        budget.stacks.append(stack)
        budget.saveBudget()
    }
}

struct BalanceEditView: View {
    @EnvironmentObject var budget: Budget
    
    var body: some View {
        List {
            ForEach($budget.balances, id: \.id) {
                $bal in
                BalanceEditorView(balance: bal)
                    .swipeActions(edge: .leading) {
                        Button("Clone") {
                            let copy = bal.copy() as! Balance
                            self.cloneBalance(from: copy)
                        }
                        .tint(.blue)
                    }
            }
            .onDelete(perform: self.deleteBalance)
            .onMove(perform: self.moveBalance)
        }
        .navigationTitle("Balances")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                EditButton()
                Image(systemName: "plus")
                    .onTapGesture(count: 1, perform: self.addBalance)
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private func deleteBalance (at offset: IndexSet) {
        budget.balances.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveBalance (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.balances.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    private func addBalance () {
        budget.balances.append(Balance())
        budget.saveBudget()
    }
    private func cloneBalance (from balance: Balance) {
        budget.balances.append(balance)
        budget.saveBudget()
    }
}

//TODO: can this be combined with BudgetItemEditView?
struct IncomeEditView: View {
    @EnvironmentObject var budget: Budget
        
    var body: some View {
        List {
            ForEach($budget.incomes, id: \.id) {
                $item in
                TransactionView(transaction: item)
                    .swipeActions(edge: .leading) {
                        Button("Clone") {
                            self.cloneIncome(from: item)
                        }
                        .tint(.blue)
                    }
            }
            .onDelete(perform: self.deleteIncome)
            .onMove(perform: self.moveIncome)
        }
        .navigationTitle("Income")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                EditButton()
                Image(systemName: "plus")
                    .onTapGesture(count: 1, perform: self.addIncome)
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private func deleteIncome (at offset: IndexSet) {
        budget.incomes.remove(atOffsets: offset)
        budget.saveBudget()
        budget.objectWillChange.send()
    }
    private func moveIncome (at offset: IndexSet, to index: Int) {
        DispatchQueue.main.async {
            budget.incomes.move(fromOffsets: offset, toOffset: index)
            budget.saveBudget()
        }
    }
    public func addIncome () {
        budget.incomes.insert(Transaction(), at: 0)
        budget.saveBudget()
    }
    private func cloneIncome (from item: Transaction) {
        let copy = item.copy() as! Transaction
        budget.incomes.insert(copy, at: 0)
        budget.saveBudget()
    }
}

//Modifier for text field to make all text fields select all when tapped
//If this can be achieved better it should, otherwise this is dumb and done
//struct TextfieldSelectAllModifier: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
//                if let textField = obj.object as? UITextField {
//                    textField.selectAll(self)
//                }
//            }
//    }
//}

// Preview
#Preview {
    NavigationStack {
        BudgetView().environmentObject(Budget())
    }
}
