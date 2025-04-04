//
//  ConnectBankButton.swift
//  Stacks
//
//  Created by Zach Hofmeister on 4/3/25.
//

import SwiftUI
import TellerKit

struct ConnectBankButton: View {
    @State var isPresented : Bool = false
    
    var body: some View {
        Button(action: {isPresented = true}) {
            Label("Connect Bank Account", systemImage: "dollarsign.bank.building")
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
                //                    print(BankData.shared.authList)
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
