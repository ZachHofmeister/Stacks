//
//  BankDataList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 4/4/25.
//

import SwiftUI
import TellerKit

struct BankDataView: View {
    @ObservedObject private var bankData = BankData.shared
    @State var isPresented : Bool = false
    
    var body: some View {
        VStack {
            List {
                ForEach (bankData.authList, id: \.accessToken) { auth in
//                    Text(await auth.accountStrings())
                }
            }
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
                Button(action: { isPresented = true }) {
                    Text("Connect Account")
                        .buttonStyle(.bordered)
                        .font(.system(size: 18))
                    //For some reason a label instead of text prevents this from working...
        //            Label("Connect New", systemImage: "plus")
                }
            }
        }
        .tellerConnect(isPresented: $isPresented, config: Teller.Config(
            appId: getAppID(),
            environment: .sandbox,
            selectAccount: .multiple,
            products: [.transactions, .balance]
        ) { reg in
            switch reg {
            case .exit:
                break
            case .enrollment(let auth):
                BankData.shared.addAuth(auth)
            default:
                break
            }
        })
    }
    
    func getAppID() -> String {
        guard let path = Bundle.main.path(forResource: "tempCreds", ofType: "json") else {return ""}
        var appId = ""
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let jsonDict = try JSONDecoder().decode([String: String].self, from: data)
            appId = jsonDict["appId"] ?? ""
        } catch let error {
            print (error)
        }
        return appId
    }
}

#Preview {
    NavigationStack {
        BankDataView()
    }
}
