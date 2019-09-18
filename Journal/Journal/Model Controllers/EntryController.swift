//
//  EntryController.swift
//  Journal
//
//  Created by Jordan Christensen on 9/17/19.
//  Copyright © 2019 Mazjap Co Technologies. All rights reserved.
//

import Foundation
import CoreData

enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

class EntryController {
    
    init() {
        fetchEntriesFromServer()
    }
    
    let baseURL = URL(string: "https://journal-f6d15.firebaseio.com/")!
    
    func put(entry: Entry, completion: @escaping () -> Void = { }) {
        
        let identifier = entry.identifier ?? UUID()
        entry.identifier = identifier
        
        let requestURL = baseURL
            .appendingPathComponent(identifier.uuidString)
            .appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.put.rawValue
        
        guard let entryRepresentation = entry.entryRepresentation else {
            NSLog("Entry Representation is nil")
            completion()
            return
        }
        
        do {
            request.httpBody = try JSONEncoder().encode(entryRepresentation)
        } catch {
            NSLog("Error encoding entry representation: \(error)")
            completion()
            return
        }
        
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            
            if let error = error {
                NSLog("Error PUTting entry: \(error)")
                completion()
                return
            }
            
            completion()
        }.resume()
    }
    
    func fetchEntriesFromServer(completion: @escaping () -> Void = { }) {
        
        let requestURL = baseURL.appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error fetching entries: \(error)")
                completion()
            }
            
            guard let data = data else {
                NSLog("No data returned from data entries")
                completion()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                
                let entryReprentations = try decoder.decode([String: EntryRepresentation].self, from: data).map({ $0.value })
                
                self.updateEntries(with: entryReprentations)
                
            } catch {
                NSLog("Error decoding: \(error)")
            }
            
        }.resume()
    }
    
    func saveToPersistentStore() {
        do {
            try CoreDataStack.shared.mainContext.save()
        } catch {
            NSLog("Error saving context: \(error)")
            CoreDataStack.shared.mainContext.reset()
        }
    }
    
    @discardableResult
    func createEntry(with title: String, bodyText: String, mood: EntryMood) -> Entry {
        let entry = Entry(title: title, bodyText: bodyText, mood: mood, context: CoreDataStack.shared.mainContext)
        saveToPersistentStore()
        return entry
    }
    
    func updateEntries(with representations: [EntryRepresentation]) {
        
        let identifiersToFetch = representations.compactMap({ UUID(uuidString: $0.identifier) })
        
        // [UUID: TaskRepresentation]
        
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, representations))
        
        // Make a mutable copy of the dictionary above
        var entriesToCreate = representationsByID
        
        do {
            let context = CoreDataStack.shared.mainContext
            
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            
            // identifier == \(identifier)
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
            
            // Which of these tasks exist in Core Data already?
            let existingEntries = try context.fetch(fetchRequest)
            
            // Which need to be updated? Which need to be put into Core Data?
            for entry in existingEntries {
                guard let identifier = entry.identifier,
                    // This gets the task representation that corresponds to the task from Core Data
                    let representation = representationsByID[identifier] else { continue }
                
                entry.title = representation.title
                entry.bodyText = representation.bodyText
                entry.mood = representation.mood
                
                entriesToCreate.removeValue(forKey: identifier)
            }
            
            // Take the tasks that AREN'T in Core Data and create new ones for them.
            for representation in entriesToCreate.values {
                Entry(entryRepresentation: representation, context: context)
            }
            
            saveToPersistentStore()
            
        } catch {
            NSLog("Error fetching entries from persistent store: \(error)")
        }
    }
    
    func updateEntry(entry: Entry, with title: String, bodyText: String, mood: EntryMood) {
        entry.title = title
        entry.bodyText = bodyText
        entry.mood = mood.rawValue
        entry.timeStamp = Date()
        
        saveToPersistentStore()
    }
    
    func deleteEntry(entry: Entry) {
        CoreDataStack.shared.mainContext.delete(entry)
        saveToPersistentStore()
    }
}
