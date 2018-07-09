//
//  SearchGroupsViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 9/18/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import CoreData
import Contacts
import Alamofire
import AlamofireImage
import Firebase

class SearchGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var searchCriteriaSegmentedControl: UISegmentedControl!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
    
    var user: User!
    var groups: [Group] = []
    let screenSize = UIScreen.main.bounds
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchKey: String!
    var tableViewShrunk = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        myTableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Enter a group name..."
        
        self.navigationController?.navigationBar.isTranslucent = false

        myTableView.tintColor = GlobalFunctions.shared.themeColor()
        
        self.myTableView.rowHeight = 90.0
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unsubscribeFromKeyboardNotifications()
        searchController.isActive = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var group: Group!
        let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineWithImage") as! TwoLineWithImageCell
        group = groups[indexPath.row]

        cell.setUpCell(group: group)
        cell.myImageView.image = nil
        
        let imageRef = Storage.storage().reference(withPath: "/\(group.uid).jpg")
        imageRef.getMetadata { (metadata, error) -> () in
            if let metadata = metadata {
                let downloadUrl = metadata.downloadURL()
                    Alamofire.request(downloadUrl!, method: .get).responseImage { response in
                        guard let image = response.result.value else {
                            return
                        }
                    cell.myImageView.image = image
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        searchController.isActive = false
    
        tableView.deselectRow(at: indexPath, animated: false)
        
        var selectedGroup: Group!
        selectedGroup = groups[indexPath.row]
        
        let alertController = UIAlertController(title: "Password Required", message: "Enter the password to join the group \"\(selectedGroup.name)\"", preferredStyle: .alert)
            
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                if selectedGroup.password == field.text {
                        
                    var updatedGroups = self.user.groups
                    updatedGroups.append(selectedGroup.uid)
                        
                    var updatedUsers = selectedGroup.users
                    let member = Member(uid: self.user.uid, name: self.user.name)
                    updatedUsers.append(member)
                        
                    FirebaseClient.shared.joinGroup(userUid: self.user.uid, groupUid: selectedGroup.uid, groups: updatedGroups, users: updatedUsers) { (success) in
                        if let success = success {
                            self.defaults.setValue(true, forKey: "shouldUpdateGroups")
                            if success {
                                self.user.groups = updatedGroups
                                let groupsVC = self.navigationController?.viewControllers[0] as! GroupsViewController
                                groupsVC.user = self.user
                                self.navigationController?.popViewController(animated: true)
                            } else {
                                self.displayAlert(title: "Error", message: "We were unable to join the group for you. Please try again.")
                            }
                        }
                    }
                    
                } else {
                    
                    let alert = UIAlertController(title: "Incorrect Password", message: "Please try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: false, completion: nil)
                    
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
        alertController.addTextField { (textField) in
            textField.textAlignment = .center
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
            
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
            
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(SearchGroupsViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchGroupsViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if (!tableViewShrunk) {
            myTableView.frame.size.height -= getKeyboardHeight(notification: notification)
        }
        tableViewShrunk = true
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if (tableViewShrunk) {
            myTableView.frame.size.height += getKeyboardHeight(notification: notification)
        }
        tableViewShrunk = false
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func performSearch(key: String) {
        if GlobalFunctions.shared.hasConnectivity() {
            let query = searchController.searchBar.text!.lowercased()
            if query != "" {
                FirebaseClient.shared.queryGroups(query: query, searchKey: key) { (groups, error) -> () in
                    self.groups = []
                    if let groups = groups {
                        for group in groups {
                            if !self.user.groups.contains(group.uid) {
                                self.groups.append(group)
                            }
                        }
                        self.groups.sort { $0.name < $1.name }
                    }
                    self.myTableView.reloadData()
                }
            } else {
                self.myTableView.reloadData()
            }
        } else {
            self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
        }
    }
    
    func performSearch() {
        if GlobalFunctions.shared.hasConnectivity() {
            let groupUid = searchController.searchBar.text!
            if groupUid != "" {
                FirebaseClient.shared.getGroup(groupUid: groupUid) { (group, error) -> () in
                    self.groups = []
                    if let group = group {
                        if !self.user.groups.contains(group.uid) {
                            self.groups = [group]
                        }
                        self.myTableView.reloadData()
                    } else {
                        self.myTableView.reloadData()
                    }
                }
            } else {
                self.myTableView.reloadData()
            }
        } else {
            self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
        }
    }
    
    @IBAction func searchCriteriaChanged(_ sender: Any) {
        switch (searchCriteriaSegmentedControl.selectedSegmentIndex) {
            case 0:
                searchController.searchBar.placeholder = "Enter a group name..."
                performSearch(key: "lowercasedName")
            case 1:
                searchController.searchBar.placeholder = "Enter a group creator's name..."
                performSearch(key: "lowercasedCreatedBy")
            case 2:
                searchController.searchBar.placeholder = "Enter a group Unique ID..."
                performSearch()
            default:
                searchController.searchBar.placeholder = "Enter a group name..."
                performSearch(key: "lowercasedName")
        }

    }
    
}

extension SearchGroupsViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        if searchController.isActive {
            switch (searchCriteriaSegmentedControl.selectedSegmentIndex) {
                case 0: performSearch(key: "lowercasedName")
                case 1: performSearch(key: "lowercasedCreatedBy")
                case 2: performSearch()
                default: ()
            }
        }
    }
}


