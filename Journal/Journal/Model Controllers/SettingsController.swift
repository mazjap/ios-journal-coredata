//
//  DarkModeController.swift
//  Journal
//
//  Created by Jordan Christensen on 9/18/19.
//  Copyright © 2019 Mazjap Co Technologies. All rights reserved.
//

import Foundation

class SettingsController {
    
    let userDefaults = UserDefaults.standard
    var isDarkMode = false
    
    init() {
        loadFromPersistentStore()
    }
    
    func loadFromPersistentStore() {
        isDarkMode = UserDefaults.standard.bool(forKey: "darkMode")
    }
    
    func saveToPersistentStore() {
        userDefaults.set(isDarkMode, forKey: "darkMode")
    }
}
