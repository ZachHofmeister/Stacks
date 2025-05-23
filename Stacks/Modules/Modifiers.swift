//
//  Modifiers.swift
//  Stacks
//
//  Created by Zach Hofmeister on 5/23/25.
//

import Foundation
import SwiftUI

//Modifier for textfields in Stack
struct BudgetTextfieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height:36)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(10)
            .multilineTextAlignment(.center)
    }
}
