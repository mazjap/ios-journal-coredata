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
                let entryRepresentations = try decoder.decode([String: EntryRepresentation].self, from: data).map({ $0.value })
                
                self.updateEntries(with: entryRepresentations)
                self.save()
                
            } catch {
                NSLog("Error decoding: \(error)")
            }
            
        }.resume()
    }
    
    func fetchSingleEntryFromPersistentStore(identifier: String, context: NSManagedObjectContext) -> Entry? {
        var tempEntry: Entry?
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "identifier", ascending: true)]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.mainContext, sectionNameKeyPath: "identifier", cacheName: nil)
        
        do {
            try frc.performFetch()
            
            tempEntry = frc.object(at: IndexPath(row: 0, section: 0))
        } catch {
            NSLog("Error performing fetch for frc: \(error)")
        }
        
        return tempEntry
    }
    
    func deleteEntryFromServer(entry: Entry, completion: @escaping () -> Void = { }) {
        
        let identifier = entry.identifier ?? UUID().uuidString
        entry.identifier = identifier
        
        let requestURL = baseURL
            .appendingPathComponent(identifier)
            .appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.delete.rawValue
        
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
                NSLog("Error Deleting entry: \(error)")
                completion()
                return
            }
            completion()
        }.resume()
    }
    
    func save(context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        context.performAndWait {
            do {
                try context.save()
            } catch {
                NSLog("Error saving context: \(error)")
                context.reset()
            }
        }
    }
    
    func updateEntries(with entryRepresentations: [EntryRepresentation]) {
        let context = CoreDataStack.shared.container.newBackgroundContext()
        context.performAndWait {
            for i in 0...entryRepresentations.count-1 {
                if let entry = self.fetchSingleEntryFromPersistentStore(identifier: entryRepresentations[i].identifier, context: CoreDataStack.shared.mainContext) {
                    if entry != entryRepresentations[i] {
                        self.update(entry: entry, entryRep: entryRepresentations[i])
                    }
                } else {
                    self.createEntry(with: entryRepresentations[i].title, bodyText: entryRepresentations[i].bodyText ?? "", mood: EntryMood(rawValue: entryRepresentations[i].mood) ?? EntryMood.😐)
                }
            }
        }
    }
    
    @discardableResult
    func createEntry(with title: String, bodyText: String, mood: EntryMood) -> Entry {
        let entry = Entry(title: title, bodyText: bodyText, mood: mood, context: CoreDataStack.shared.mainContext)
        save()
        put(entry: entry)
        return entry
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
        
        save()
        put(entry: entry)
    }
    
    func deleteEntry(entry: Entry) {
        CoreDataStack.shared.mainContext.delete(entry)
        deleteEntryFromServer(entry: entry)
        save()
    }
}
