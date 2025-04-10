//
//  ContentView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/7/22.
//

import SwiftUI
import TellerKit

struct ContentView: View {
    @StateObject private var budget = Budget()
    
    var body: some View {
        NavigationStack {
            BudgetListView()
        }
        .environmentObject(budget)
    }
}

// Preview
#Preview {
    ContentView()
}
