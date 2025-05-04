//
//  BankData.swift
//  Stacks
//
//  Created by Zach Hofmeister on 4/2/25.
//

import Foundation
import TellerKit

class BankData : ObservableObject {
    //Singleton
    static let shared = BankData()
    private let plistUrl: URL
    @Published private(set) var auths: [Teller.Authorization]
    @Published private(set) var accounts: [String: [Teller.Account]]?
    
    private init() {
        let docsUrl = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first!
        
        //Create BankData folder in documents directory if not existing
        let bankDataURL = docsUrl.appendingPathComponent("BankData")
        do {
            try FileManager.default.createDirectory(atPath: bankDataURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print("Error creating BankData directory: \(error)")
        }
        
        // Create BankData.plist if not existing
        self.plistUrl = bankDataURL.appendingPathComponent("BankData").appendingPathExtension("plist")
        guard FileManager.default.fileExists(atPath: self.plistUrl.path) else {
            self.auths = []
            return
        }
        
        //Read AuthList
        var authList: [Teller.Authorization] = []
        do {
            let plistData = try Data(contentsOf: plistUrl)
            authList = try PropertyListDecoder().decode([Teller.Authorization].self, from: plistData)
        } catch let error {
            print("Error reading BankData.plist: \(error)")
        }
        
        self.auths = authList
        
        for auth in authList {
            var array: [Teller.Account] = []
            Task {
                array = try await getAccounts(auth: auth)
            }
            self.accounts?[auth.accessToken] = array
        }
    }
    
    func save() {
        let plistEncoder = PropertyListEncoder()
        do {
            let encoded = try plistEncoder.encode(self.auths)
            try encoded.write(to: self.plistUrl, options: .noFileProtection)
        } catch let error {
            print("Error saving BankData.plist: \(error)")
        }
    }
    
    func addAuth(_ auth: Teller.Authorization) {
        self.auths.append(auth)
        self.save()
    }
    
    func getAccounts(auth: Teller.Authorization) async throws -> [Teller.Account] {
        guard let url = URL(string: "https://api.teller.io/accounts") else { return [] }
        var request = URLRequest(url: url)
        //Format accessToken and insert as request header
        let loginString = "\(auth.accessToken):"
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.allHTTPHeaderFields = ["Authorization": "Basic \(base64LoginString)"]
        
        //Call API request
        var accounts: [Teller.Account] = []
        let (data, _) = try await URLSession.shared.data(for: request)
        do {
            accounts = try JSONDecoder().decode([Teller.Account].self, from: data) //could throw typeMismatch if Teller.Error is returned
        } catch let DecodingError.typeMismatch(type, context) {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
            // Print the JSON error returned from call
            guard let object = try? JSONSerialization.jsonObject(with: data, options: []) else { return []}
            print(object)
        } catch let error {
            print(error)
        }
        return accounts
    }
    
    func printAll() async throws {
        guard let url = URL(string: "https://api.teller.io/accounts") else { return }
        for auth in self.auths {
            var request = URLRequest(url: url)
            //Format accessToken and insert as request header
            let loginString = "\(auth.accessToken):"
            let loginData = loginString.data(using: String.Encoding.utf8)!
            let base64LoginString = loginData.base64EncodedString()
            request.allHTTPHeaderFields = ["Authorization": "Basic \(base64LoginString)"]
            
            //Call API request
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard error == nil else { return }
                guard let data = data else { return }
                do {
                    let accounts = try JSONDecoder().decode([Teller.Account].self, from: data) //could throw typeMismatch if Teller.Error is returned
                    for acct in accounts {
//                        print("\(acct)\n")
                        print("\(acct.institution.name) \(acct.subtype) \(acct.lastFour)")
                    }
                } catch let DecodingError.typeMismatch(type, context) {
                    print("Type '\(type)' mismatch:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                    // Print the JSON error returned from call
                    guard let object = try? JSONSerialization.jsonObject(with: data, options: []) else { return }
                    print(object)
                } catch let error {
                    print(error)
                }
            }
            task.resume()
        }
    }
}
