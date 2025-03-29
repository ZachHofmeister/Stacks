//
//  BudgetList.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/20/23.
//

import Foundation

//Singleton class, list of all budget plists
class BudgetList: ObservableObject {
    static let shared = BudgetList()
    @Published private(set) var urlList: [URL]
    
    //initializes the urlList
    private init() {
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
        newBudget.save()
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
