//
//  BankDataList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 4/4/25.
//

import SwiftUI

struct BankDataView: View {
    @ObservedObject private var bankData = BankData.shared
    
    var body: some View {
        VStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            Button("PRINT") {
                Task {
                    do {
                        try await BankData.shared.printAll()
                    } catch {
                        print (error)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ConnectBankButton()
            }
        }
    }
}

#Preview {
    BankDataView()
}
