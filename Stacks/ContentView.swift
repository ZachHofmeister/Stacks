//
//  ContentView.swift
//  Stacks
//
//  Created by Zach Hofmeister on 8/7/22.
//

import SwiftUI
import TellerKit

struct ContentView: View {
    @State var tellerPresented : Bool = false
    
    var body: some View {
        Button(action: {tellerPresented = true}) {
            Label("Connect Bank Account", systemImage: "dollarsign.bank.building")
        }
        .tellerConnect(isPresented: $tellerPresented, config: Teller.Config(
                appId: "APPID",
                environment: .sandbox,
                selectAccount: .multiple,
                products: [.transactions, .balance]
            ) { reg in
                switch reg {
                case .exit:
                    break
                case .enrollment(let auth):
                    BankData.shared.addAuth(auth)
//                    print(BankData.shared.authList)
                default:
                    break
                }
            })
        Button("PRINT") {
            Task {
                do {
                    try await BankData.shared.printAllAuthedFours()
                } catch {
                    print (error)
                }
            }
        }
        BudgetListView()
    }
}

// Preview
#Preview {
    ContentView()
}
