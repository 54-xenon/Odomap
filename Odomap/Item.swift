//
//  Item.swift
//  Odomap
//
//  Created by とくおかけいと on 2026/07/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
