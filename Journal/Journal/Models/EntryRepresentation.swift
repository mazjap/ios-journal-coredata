//
//  EntryRepresentation.swift
//  Journal
//
//  Created by Jordan Christensen on 9/19/19.
//  Copyright © 2019 Mazjap Co Technologies. All rights reserved.
//

import Foundation

struct EntryRepresentation: Codable {
    let title: String
    let bodyText: String?
    let timeStamp: Date
    let identifier: String
    let mood: String
}

extension EntryRepresentation: Equatable {
    static func == (lhs: EntryRepresentation, rhs: Entry) -> Bool {
        return lhs.title == rhs.title &&
                lhs.bodyText == rhs.bodyText &&
                lhs.timeStamp == rhs.timeStamp &&
                lhs.identifier == rhs.identifier &&
                lhs.mood == rhs.mood
    }
    
    static func == (lhs: Entry, rhs: EntryRepresentation) -> Bool {
        return rhs == lhs
    }
    
    static func != (lhs: Entry, rhs: EntryRepresentation) -> Bool {
        return !(rhs == lhs)
    }
}
