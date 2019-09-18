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
        
        let identifier = entry.identifier ?? UUID().uuidString
        entry.identifier = identifier
        
        let requestURL = baseURL
            .appendingPathComponent(identifier)
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
    
    func fetchSingleEntryFromPersistentStore(identifier: String) -> Entry? {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@")
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.mainContext, sectionNameKeyPath: "identifier", cacheName: nil)
        
        do {
            try frc.performFetch()
            return frc.object(at: IndexPath(row: 0, section: 0))
        } catch {
            fatalError("Error performing fetch for frc: \(error)")
        }
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
        put(entry: entry)
        return entry
    }
    
    func updateEntries(with representations: [EntryRepresentation]) {
        let identifiersToFetch = representations.compactMap({ UUID(uuidString: $0.identifier) })
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, representations))
        var entriesToCreate = representationsByID
        
        do {
            let context = CoreDataStack.shared.mainContext
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifiersToFetch)
            let existingEntries = try context.fetch(fetchRequest)
            for entry in existingEntries {
                guard let identifier = entry.identifier,
                    let representation = representationsByID[UUID(uuidString: identifier) ?? UUID()] else { continue }
                
                entry.title = representation.title
                entry.bodyText = representation.bodyText
                entry.mood = representation.mood
                
                entriesToCreate.removeValue(forKey: UUID(uuidString: identifier) ?? UUID())
            }
            
            for representation in entriesToCreate.values {
                Entry(entryRepresentation: representation, context: context)
            }
            
            saveToPersistentStore()
            
        } catch {
            NSLog("Error fetching entries from persistent store: \(error)")
        }
    }
    
    func update(entry: Entry, entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.timeStamp = entryRep.timeStamp
        entry.mood = entryRep.mood
        entry.identifier = entryRep.identifier
    }
    
    func updateEntry(entry: Entry, with title: String, bodyText: String, mood: EntryMood) {
        entry.title = title
        entry.bodyText = bodyText
        entry.mood = mood.rawValue
        entry.timeStamp = Date()
        
        saveToPersistentStore()
        put(entry: entry)
    }
    
    func deleteEntry(entry: Entry) {
        CoreDataStack.shared.mainContext.delete(entry)
        saveToPersistentStore()
    }
}
