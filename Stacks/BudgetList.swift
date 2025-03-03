//
//  BudgetList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/20/23.
//

import Foundation
import SwiftUI

class BudgetList: ObservableObject {
    @Published var urlList: [URL]
    
    //initializes the urlList
    init() {
        let docsUrl = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
        var docsContents: [URL] = []
        do {
            docsContents = try FileManager.default.contentsOfDirectory(at: docsUrl, includingPropertiesForKeys: nil)
        } catch {
            print("Error: could not init BudgetList")
            print(error.localizedDescription)
        }
        self.urlList = docsContents.filter { $0.pathExtension == "plist" } //all plists in documents folder
    }
    
    func createBudget() {
        let newBudget = Budget()
        newBudget.saveBudget()
        urlList.append(newBudget.budgetUrl)
    }
    
    func deleteBudget (at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            urlList.removeAll(where: {$0 == url}) //remove the matching url from the list
        } catch {
            print(error.localizedDescription)
        }
    }
}

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
