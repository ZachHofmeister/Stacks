//
//  Transactions.swift
//  Stacks
//
//  Created by Zach Hofmeister on 5/20/25.
//

import Foundation

class Transactions : ObservableObject {
    @Published var list: [Transaction]
    
    init(_ list: [Transaction] = []) {
        self.list = list
    }
}
