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
        
        //Create BudgetList folder in documents directory if not existing
        let budgetListURL = docsUrl.appendingPathComponent("BudgetList")
        do {
            try FileManager.default.createDirectory(atPath: budgetListURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print("Error creating directory: \(error)")
        }
        
        // Get all plists in documents folder
        var docsContents: [URL] = []
        do {
            docsContents = try FileManager.default.contentsOfDirectory(at: docsUrl, includingPropertiesForKeys: nil)
        } catch let error {
            print("Error getting plists in docs folder: \(error)")
        }
        let plistInDocsURL = docsContents.filter { $0.pathExtension == "plist" }
        
        // Move all plists in documents folder to BudgetList folder - migration from storing only budgets as plists in documents root
        for url in plistInDocsURL {
            let newURL = budgetListURL.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: newURL.path) {
                    try FileManager.default.removeItem(atPath: newURL.path)
                }
                try FileManager.default.moveItem(atPath: url.path, toPath: newURL.path)
                print("The new URL: \(newURL)")
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // Get all plists in BudgetList folder
        var budgetListContents: [URL] = []
        do {
            budgetListContents = try FileManager.default.contentsOfDirectory(at: budgetListURL, includingPropertiesForKeys: nil)
        } catch let error {
            print("Error getting plists in BudgetList folder: \(error)")
        }
        
        //set urlList to plist URLs in BudgetList folder
        self.urlList = budgetListContents.filter { $0.pathExtension == "plist" }
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
