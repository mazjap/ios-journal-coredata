//
//  EntriesTableViewController.swift
//  Journal
//
//  Created by Jordan Christensen on 9/17/19.
//  Copyright © 2019 Mazjap Co Technologies. All rights reserved.
//

import UIKit
import CoreData

class EntriesTableViewController: UITableViewController {
    
    @IBOutlet weak var darkModeButton: UIBarButtonItem!
    @IBOutlet weak var noEntriesLabel: UILabel!
    
    let entryController = EntryController()
    let settingsController = SettingsController()
    
    lazy var fetchRequestController: NSFetchedResultsController<Entry> = {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "mood", ascending: true),
                                        NSSortDescriptor(key: "timeStamp", ascending: true)]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.mainContext, sectionNameKeyPath: "mood", cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            fatalError("Error performing fetch for frc: \(error)")
        }
        
        return frc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = 50;
        
        setUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if fetchRequestController.sections?.count ?? 0 >= 1 {
            noEntriesLabel.isHidden = true
        } else {
            noEntriesLabel.isHidden = false
        }
        
        tableView.reloadData()
    }
    
    func setUI() {
        if settingsController.settings.isDarkMode {
            navigationController?.navigationBar.barTintColor = .darkBackground
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.darkTextColor]
            navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.darkTextColor]
            navigationController?.navigationBar.tintColor = .darkTextColor
            darkModeButton.tintColor = .darkTextColor
        
            noEntriesLabel.backgroundColor = .darkBackground
            noEntriesLabel.textColor = .darkTextColor
            
            view.backgroundColor = .darkBackground
        } else {
            navigationController?.navigationBar.barTintColor = .lightBackground
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.lightTextColor]
            navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.lightTextColor]
            navigationController?.navigationBar.tintColor = UIColor(red:0.07, green:0.42, blue:1.00, alpha:1.00)
            darkModeButton.tintColor = .black
            
            noEntriesLabel.backgroundColor = .white
            noEntriesLabel.textColor = .black
            
            view.backgroundColor = .white
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchRequestController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return fetchRequestController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "JournalCell", for: indexPath) as? EntryTableViewCell else { return UITableViewCell() }
        
        cell.settingsController = settingsController
        cell.entry = fetchRequestController.object(at: indexPath)

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let entry = fetchRequestController.object(at: indexPath)
            entryController.deleteEntry(entry: entry)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionInfo = fetchRequestController.sections?[section] else { return nil }

        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        if settingsController.settings.isDarkMode {
            returnedView.backgroundColor = .darkSectionHeaderBackground
        } else {
            returnedView.backgroundColor = .lightSectionHeaderBackground
        }

        let label = UILabel(frame: CGRect(x: 18, y: 3.5, width: returnedView.frame.width, height: returnedView.frame.height))

        label.text = sectionInfo.name.capitalized
        returnedView.addSubview(label)

        return returnedView
    }


    @IBAction func toggleDarkMode(_ sender: Any) {
        settingsController.settings.isDarkMode = !settingsController.settings.isDarkMode
        settingsController.saveToPersistentStore()
        setUI()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowJournalDetailSegue" {
            guard let detailVC = segue.destination as? EntryDetailViewController,
                let indexPath = tableView.indexPathForSelectedRow else { return }
            detailVC.settingsController = settingsController
            detailVC.entryController = entryController
            detailVC.entry = fetchRequestController.object(at: indexPath)
        } else if segue.identifier == "ShowAddJournalSegue" {
            guard let detailVC = segue.destination as? EntryDetailViewController else { return }
            detailVC.entryController = entryController
            detailVC.settingsController = settingsController
        }
    }
}

extension EntriesTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        case .move:
            guard let indexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.moveRow(at: indexPath, to: newIndexPath)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        @unknown default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(sectionSet, with: .automatic)
        case .delete:
            tableView.deleteSections(sectionSet, with: .automatic)
        default:
            return
        }
    }
}
