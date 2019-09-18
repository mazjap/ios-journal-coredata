//
//  Entry.swift
//  Journal
//
//  Created by Jordan Christensen on 9/17/19.
//  Copyright © 2019 Mazjap Co Technologies. All rights reserved.
//

import Foundation
import CoreData

enum EntryMood: String, CaseIterable {
    case 🤬
    case 😐
    case 😆
}

extension Entry {
    convenience init(title: String, bodyText: String, mood: EntryMood = .😐, identifier: UUID = UUID(), context: NSManagedObjectContext) {
        self.init(context: context)
        self.title = title
        self.bodyText = bodyText
        self.timeStamp = Date()
        self.identifier = identifier
        self.mood = mood.rawValue
    }
}
