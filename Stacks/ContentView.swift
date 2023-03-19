//
//  ContentView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/7/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var budget = Budget()
    private var budgetFileUrls: [URL] = getBudgetFileUrls()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(budgetFileUrls, id: \.self) {
                    url in
                    // onAppear is used to change the Budget environment object
                    NavigationLink(destination: BudgetView().onAppear{budget.loadPlist(from: url)}) {
                        Label(url.lastPathComponent, systemImage: "book")
                    }
//                    .simultaneousGesture(TapGesture().onEnded {
//                        budget.loadPlist(url: url)
//                    })
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Welcome to Stacks!")
            .toolbar(.hidden, for: .bottomBar)
        }
        .environmentObject(budget)
    }
}

func getBudgetFileUrls() -> [URL] {
    let budgetFileURL: URL = (
        FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
    ).appendingPathComponent("budget").appendingPathExtension("plist")
    let budgetFile2URL: URL = (
        FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
    ).appendingPathComponent("budget2").appendingPathExtension("plist")
    return [budgetFileURL, budgetFile2URL]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
