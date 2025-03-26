//
//  BudgetFile.swift
//  Stacks
//
//  Created by Zach Hofmeister on 3/17/23.
//  A FileDocument used to export / import budgets (essentially a plist with .budget as the extension)
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct BudgetFile : FileDocument {
    // supports property list format
    static var readableContentTypes = [UTType.json]
    
    // empty document
    var text = ""
    
    // simple initializer
    init(initialText: String = "") {
        text = initialText
    }
    
    // loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    // init from data (as in encoded property list data)
    init(data: Data) {
        text = String(decoding: data, as: UTF8.self)
    }
    
    //will be called when system is writing data
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
