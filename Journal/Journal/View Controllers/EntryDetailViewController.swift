//
//  EntryDetailViewController.swift
//  Journal
//
//  Created by Jordan Christensen on 9/17/19.
//  Copyright © 2019 Mazjap Co Technologies. All rights reserved.
//

import UIKit

class EntryDetailViewController: UIViewController {
    
    var isDarkMode: Bool?
    var entryController: EntryController?
    var entry: Entry? {
        didSet {
            updateViews()
        }
    }
    
    @IBOutlet weak var moodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var journalEntryTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moodSegmentedControl.selectedSegmentIndex = 1
        moodSegmentedControl.setTitleTextAttributes(
            [NSAttributedString.Key.foregroundColor:UIColor.white], for: .selected)
        
        setUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        updateViews()
    }
    
    func setUI() {
        if let isDarkMode = isDarkMode, isDarkMode {
            navigationController?.navigationBar.barTintColor = .background
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.textColor]
            navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.textColor]
            
            titleTextField.backgroundColor = .textFieldBackground
            titleTextField.attributedPlaceholder = NSAttributedString(string: "Enter Title:",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            titleTextField.textColor = .textColor
            
            journalEntryTextView.layer.borderWidth = 0.5
            journalEntryTextView.layer.borderColor = UIColor(displayP3Red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3).cgColor
            journalEntryTextView.layer.cornerRadius = 6
            journalEntryTextView.backgroundColor = .textFieldBackground
            journalEntryTextView.textColor = .textColor
            
            view.backgroundColor = .background
        } else {
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
            navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
            
            titleTextField.backgroundColor = .lightGray
            titleTextField.attributedPlaceholder = NSAttributedString(string: "Enter Title:",
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
            titleTextField.textColor = .textColor
            
            journalEntryTextView.layer.borderWidth = 0.5
            journalEntryTextView.layer.borderColor = UIColor(displayP3Red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3).cgColor
            journalEntryTextView.layer.cornerRadius = 6
            journalEntryTextView.backgroundColor = .lightGray
            journalEntryTextView.textColor = .textColor
            
            view.backgroundColor = .white
        }
    }
    
    func updateViews() {
        if isViewLoaded {
            title = entry?.title ?? "Create Journal Entry"
            
            titleTextField.text = entry?.title
            journalEntryTextView.text = entry?.bodyText
            
            if let moodString = entry?.mood,
                let mood = EntryMood(rawValue: moodString) {
                let index = EntryMood.allCases.firstIndex(of: mood)

                moodSegmentedControl.selectedSegmentIndex = index ?? 0
            }
        }
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        let mood = EntryMood.allCases[moodSegmentedControl.selectedSegmentIndex]
        
        guard let title = titleTextField.text,
            let bodyText = journalEntryTextView.text,
            !title.isEmpty, !bodyText.isEmpty else { return }
        if let entry = entry {
            entryController?.updateEntry(entry: entry, with: title, bodyText: bodyText, mood: mood)
        } else {
            entryController?.createEntry(with: title, bodyText: bodyText, mood: mood)
        }
        navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
