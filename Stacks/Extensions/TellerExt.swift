//
//  TellerExt.swift
//  Stacks
//
//  Created by Zach Hofmeister on 4/3/25.
//

import Foundation
import TellerKit

extension Teller.Authorization : @retroactive Encodable, @retroactive Hashable {
    enum CodingKeys: CodingKey {
        case accessToken, enrollment, signatures
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(enrollment, forKey: .enrollment)
        try container.encode(signatures, forKey: .signatures)
    }
    
    //Conform to hashable. Good enough for ForEach
    public func hash(into hasher: inout Hasher) {
        hasher.combine(accessToken)
    }
    public static func == (lhs: TellerKit.Teller.Authorization, rhs: TellerKit.Teller.Authorization) -> Bool {
        return lhs.accessToken == rhs.accessToken
    }
    
    public func accountStrings() async throws -> String {
        var acctStrings: String = ""
        guard let url = URL(string: "https://api.teller.io/accounts") else { return acctStrings }
        var request = URLRequest(url: url)
        //Format accessToken and insert as request header
        let loginString = "\(self.accessToken):"
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
                    acctStrings += "\(acct.institution.name) \(acct.subtype) \(acct.lastFour) "
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
        
        return acctStrings
    }
}

extension Teller.Enrollment : @retroactive Encodable {
    enum CodingKeys: CodingKey {
        case id, institution
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(institution, forKey: .institution)
    }
}

extension Teller.Institution : @retroactive Encodable {
    enum CodingKeys: CodingKey {
        case name
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
}
