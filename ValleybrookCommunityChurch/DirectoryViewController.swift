//
//  ViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import CoreData
import Contacts
import Alamofire
import AlamofireImage
import Firebase
import GoogleMobileAds
import MessageUI

class DirectoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate, UISearchControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, GADBannerViewDelegate {
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var addEntryButton: UIBarButtonItem!
    @IBOutlet weak var myTableView: UITableView!
    
    var bannerView: GADBannerView!
    @IBOutlet weak var adContainer: UIView!
    
    var group: Group!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var sections = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    
    var entries: [Entry] = []
    var filteredEntries: [Entry] = []
    var entriesWithSections: [[Entry]] = []
    var filteredEntriesWithSections: [[Entry]] = []
    var tableViewShrunk = false
    var titleViewTouch: UITapGestureRecognizer!
    
    let screenSize = UIScreen.main.bounds

    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        myTableView.sectionIndexColor = GlobalFunctions.shared.themeColor()
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        myTableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Search by Last Name..."
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        if let uid = Auth.auth().currentUser?.uid {
            if !group.getAdminUids().contains(uid) {
                addEntryButton.isEnabled = false
                addEntryButton.tintColor = UIColor.clear
            }
        }
        
        self.navigationItem.titleView = GlobalFunctions.shared.configureTwoLineTitleView("Directory", bottomLine: group.name)
        titleViewTouch = UITapGestureRecognizer(target: self, action: #selector(DirectoryViewController.showCounts))
        self.navigationItem.titleView?.isUserInteractionEnabled = true
        self.navigationItem.titleView?.addGestureRecognizer(titleViewTouch)
        
        updateData()
        
    }
    
    func showCounts() {
        if entries.count > 0 {
            var adultCount = 0
            var childCount = 0
            for entry in entries {
                adultCount += entry.personCount(personTypes: [PersonType.husband, PersonType.wife, PersonType.single])
                childCount += entry.personCount(personTypes: [PersonType.child])
            }
            self.displayAlert(title: "Counts",
                              message: "\nEntries: \(entries.count)"
                                     + "\n\nAdults: \(adultCount)"
                                     + "\nChildren: \(childCount)"
                                     + "\nTotal: \(adultCount + childCount)")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func updateData() {
        
        aiv.isHidden = false
        aiv.startAnimating()
        myTableView.isHidden = true
        
        if GlobalFunctions.shared.hasConnectivity() {
            
            FirebaseClient.shared.updateDirectory(uid: group.uid) { (entries, error) -> () in
                if let entries = entries {
                    
                    self.entries = entries
                    
                    let lastUpdateTime = GlobalFunctions.shared.getCurrentDateTime()
                    self.appDelegate.defaults.setValue(lastUpdateTime, forKey: "lastUpdated")
                    
                    self.aiv.isHidden = true
                    self.aiv.stopAnimating()
                    self.myTableView.isHidden = false
                    
                    self.displayData()
                
                } else {
                    
                    self.aiv.isHidden = true
                    self.aiv.stopAnimating()
                    self.myTableView.isHidden = false
                    
                }
            }
        } else {
            
            self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        subscribeToKeyboardNotifications()
        
        if defaults.bool(forKey: "shouldUpdateDirectory") {
            updateData()
            defaults.setValue(false, forKey: "shouldUpdateDirectory")
        }
        
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.delegate = self
        bannerView.adUnitID = "ca-app-pub-4590926477342036/8203778607"
        //bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" //test ad-unit id
        bannerView.rootViewController = self
        let request = GADRequest()
        //request.testDevices = ["191b6aacb501d4f65eef7379f19afce6"]
        bannerView.load(request)
        
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        adContainer.addSubview(bannerView)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        searchController.isActive = false
        unsubscribeFromKeyboardNotifications()
    }

    func displayData() {
        
        entriesWithSections = []
        
        self.entries.sort { $0.name! < $1.name! }
        
        for i in 0...25 {
            var tempArray: [Entry] = []
            for entry in self.entries {
                if entry.name?[0] == self.sections[i] {
                    tempArray.append(entry)
                }
            }
            entriesWithSections.append(tempArray)
        }
        
        myTableView.reloadData()
        myTableView.isHidden = false
        myTableView.setContentOffset(CGPoint(x:0,y:searchController.searchBar.frame.size.height), animated: false)
        aiv.stopAnimating()
        aiv.isHidden = true

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if searchController.isActive && searchController.searchBar.text != "" {
            if filteredEntriesWithSections.count > 0 {
                return filteredEntriesWithSections[section].count
            }
            return 0
        } else {
            if entriesWithSections.count > 0 {
                return entriesWithSections[section].count
            }
            return 0
        }

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var entries = entriesWithSections
        if searchController.isActive && searchController.searchBar.text != "" {
            entries = filteredEntriesWithSections
        }

        if entries.count > 0 {
            if entries[section].count == 0 {
                return nil
            }
            return sections[section]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var entry = entriesWithSections[indexPath.section][indexPath.row]
        if searchController.isActive && searchController.searchBar.text != "" {
            entry = filteredEntriesWithSections[indexPath.section][indexPath.row]
        }
        
        let address = entry.address
        let people = entry.people!
        
        let header = getHeader(entry: entry, people: people)
        
        let entryPhone = entry.phone
        let entryEmail = entry.email
        let addressStreet = address?.street
        let addressLine2 = address?.line2
        let addressLine3 = address?.line3
        let cityStateZip = address?.getCityStateZipString()
        let childrenString = GlobalFunctions.shared.getChildrenString(people: people)
        
        var lineCount = 1
        var lines: [String] = [header]
        
        if entryPhone != "" {
            lineCount += 1
            lines.append(entryPhone!)
        }
        if entryEmail != "" {
            lineCount += 1
            lines.append(entryEmail!)
        }
        if addressLine2 != "" {
            lineCount += 1
            lines.append(addressLine2!)
        }
        if addressLine3 != "" {
            lineCount += 1
            lines.append(addressLine3!)
        }
        if addressStreet != "" {
            lineCount += 1
            lines.append(addressStreet!)
        }
        if cityStateZip != "" {
            lineCount += 1
            lines.append(cityStateZip!)
        }
        if childrenString != "" {
            lineCount += 1
            lines.append(childrenString)
        }
        
        switch lineCount {
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OneLine") as! OneLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLine") as! TwoLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ThreeLine") as! ThreeLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FourLine") as! FourLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FiveLine") as! FiveLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SixLine") as! SixLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 7:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SevenLine") as! SevenLineCell
            cell.setUpCell(lines: lines)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OneLine") as! OneLineCell
            cell.header.text = header
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        return cell.frame.size.height
    }
    
    func getHeader(entry: Entry, people: [Person]) -> String {
        
        var husbandFirstName = ""
        var wifeFirstName = ""
        var singleFirstName = ""
        
        for person in people {
            if person.type == "Single" {
                singleFirstName = person.name!
            } else if person.type == "Husband" {
                husbandFirstName = person.name!
            } else if person.type == "Wife" {
                wifeFirstName = person.name!
            }
        }
        if singleFirstName != "" {
            return entry.name! + ", " + singleFirstName
        } else {
            return entry.name! + ", " + husbandFirstName + " & " + wifeFirstName
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if searchController.isActive {
            searchController.searchBar.isHidden = true
            searchController.searchBar.resignFirstResponder()
            let evc = storyboard?.instantiateViewController(withIdentifier: "EntryViewController") as! EntryViewController
            evc.entry = filteredEntriesWithSections[indexPath.section][indexPath.row]
            evc.group = self.group
            self.navigationController?.pushViewController(evc, animated: true)
            searchController.isActive = false
            searchController.searchBar.text = ""
        } else {
            let evc = storyboard?.instantiateViewController(withIdentifier: "EntryViewController") as! EntryViewController
            evc.entry = entriesWithSections[indexPath.section][indexPath.row]
            evc.group = self.group
            self.navigationController?.pushViewController(evc, animated: true)
            tableView.deselectRow(at: indexPath, animated: false)
        }
        
    }
    
    @IBAction func addEntryButtonPressed(_ sender: Any) {
        
        searchController.isActive = false
        
        let addEntryVC = self.storyboard?.instantiateViewController(withIdentifier: "AddEntryViewController") as! AddEntryViewController
        addEntryVC.group = self.group
        self.navigationController?.pushViewController(addEntryVC, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if !group.getAdminUids().contains((Auth.auth().currentUser?.uid)!) {
            return false
        }
        if searchController.isActive {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let entryToDelete = entriesWithSections[indexPath.section][indexPath.row]
        if editingStyle == .delete {
            
        let alert = UIAlertController(title: "Delete Entry", message: "Are you sure you want to continue?", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
            if GlobalFunctions.shared.hasConnectivity() {
                FirebaseClient.shared.deleteEntry(groupUid: self.group.uid, entryUid: entryToDelete.uid!) { (success) -> () in
                    if let success = success {
                        if success {
                            let alert = UIAlertController(title: "Success", message: "The entry was successfully removed from the database.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                self.updateData()
                            }))
                            self.present(alert, animated: false, completion: nil)
                        } else {
                            self.displayAlert(title: "Error", message: "We were unable to remove the entry from the database.")
                        }
                    } else {
                        self.displayAlert(title: "Error", message: "We were unable to remove the entry from the database.")
                    }
                }
            } else {
                self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
            }
        })

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(yes)
        alert.addAction(cancel)

        self.present(alert, animated: false, completion: nil)
            
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredEntries = entries.filter { entry in
            return (entry.name?.lowercased().contains(searchText.lowercased()))!
        }
        filteredEntriesWithSections = []
        for i in 0...25 {
            var tempArray: [Entry] = []
            for entry in self.filteredEntries {
                if entry.name?[0] == self.sections[i] {
                    tempArray.append(entry)
                }
            }
            filteredEntriesWithSections.append(tempArray)
        }
        
        myTableView.reloadData()

    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(DirectoryViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DirectoryViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if (!tableViewShrunk) {
            myTableView.frame.size.height -= (getKeyboardHeight(notification: notification) - bannerView.frame.size.height)
        }
        tableViewShrunk = true
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if (tableViewShrunk) {
            myTableView.frame.size.height += (getKeyboardHeight(notification: notification) - bannerView.frame.size.height)
        }
        tableViewShrunk = false
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController(groupToShare: Group) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setSubject("\(groupToShare.name) is on Directory Hub!")
        let body =
            "You have been invited to join a group on Directory Hub!\n\n" +
                
                "Step 1: Access Directory Hub on Web, iPhone, or Android:\n\n" +
                
                "Web: www.directoryhub.net\n" +
                "iPhone App: https://itunes.apple.com/us/app/directory-hub/id1287637768?mt=8\n" +
                "Android App: https://play.google.com/store/apps/details?id=com.ajz.directoryhub\n\n" +
                
                "Step 2: Create your personal Account\n" +
                "Step 3: On the My Groups Page, click \"Add Group\" (Web) or the \"+\" symbol (App)\n" +
                "Step 4: Select \"Search Groups\"\n" +
                "Step 5: Search for the group using any of the following 3 criteria and select it:\n\n" +
                
                "GROUP NAME: " + groupToShare.name + "\n" +
                "CREATED BY: " + groupToShare.createdBy + "\n" +
                "GROUP ID: " + groupToShare.uid + "\n\n" +
                
                "Step 6: Enter \(groupToShare.password) as the password\n" +
        "Step 7: Start using the directory!"
        mailComposerVC.setMessageBody(body, isHTML: false)
        return mailComposerVC
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mvc = configuredMailComposeViewController(groupToShare: group!)
            self.present(mvc, animated: true, completion: nil)
        } else {
            displayAlert(title: "Error", message: "This device cannot send mail.")
        }
    }
    

}

class OneLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
    }
    
}

class TwoLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
    }
    
    func setUpCell(group: Group) {
        header.attributedText = GlobalFunctions.shared.bold(string: group.name)
        let location = "\(group.city) \(group.state)"
        line2.attributedText = GlobalFunctions.shared.italics(string: location)
    }
    
}

class ThreeLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
    }
    
}

class FourLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
    }
    
}

class FiveLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    @IBOutlet weak var line5: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
        line5.text = lines[4]
    }
    
    
}

class SixLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    @IBOutlet weak var line5: UILabel!
    @IBOutlet weak var line6: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
        line5.text = lines[4]
        line6.text = lines[5]
    }
    
}

class SevenLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    @IBOutlet weak var line5: UILabel!
    @IBOutlet weak var line6: UILabel!
    @IBOutlet weak var line7: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
        line5.text = lines[4]
        line6.text = lines[5]
        line7.text = lines[6]
    }
    
}

extension String {
    
    var length: Int {
        return self.characters.count
    }
    
    subscript (i: Int) -> String {
        return self[Range(i ..< i + 1)]
    }
    
    func substring(from: Int) -> String {
        return self[Range(min(from, length) ..< length)]
    }
    
    func substring(to: Int) -> String {
        return self[Range(0 ..< max(0, to))]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[Range(start ..< end)]
    }
    
}

extension DirectoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

