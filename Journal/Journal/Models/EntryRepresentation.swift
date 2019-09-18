//
//  EntryRepresentation.swift
//  Journal
//
//  Created by Jordan Christensen on 9/19/19.
//  Copyright © 2019 Mazjap Co Technologies. All rights reserved.
//

import Foundation

struct EntryRepresentation: Codable, Equatable {
    let title: String
    let bodyText: String?
    let timeStamp: Date
    let identifier: String
    let mood: String
}
