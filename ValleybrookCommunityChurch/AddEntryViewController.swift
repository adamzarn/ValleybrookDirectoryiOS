//
//  AddEntryViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/16/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import CoreData

class AddEntryViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let defaults = UserDefaults.standard
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var delegate: EditEntryDelegate?
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var peopleTableView: UITableView!
    @IBOutlet weak var addressTableView: UITableView!
    var typePicker: UIPickerView!
    var birthOrderPicker: UIPickerView!
    var statePicker: UIPickerView!
    var dimView: UIView?
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var bottomStackView: UIStackView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var peopleLabel: UILabel!
    @IBOutlet weak var editAddressButton: UIButton!
    @IBOutlet weak var addPersonButton: UIButton!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var homePhoneTextField: UITextField!
    @IBOutlet weak var entryEmailTextField: UITextField!
    
    @IBOutlet weak var addAddressView: UIView!
    //Add Address View
    @IBOutlet weak var streetTextField: UITextField!
    @IBOutlet weak var line2TextField: UITextField!
    @IBOutlet weak var line3TextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipTextField: UITextField!
    
    @IBOutlet weak var addPersonView: UIView!
    //Add Person View
    @IBOutlet weak var addPersonLabel: UILabel!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var personTypeTextField: UITextField!
    @IBOutlet weak var birthOrderTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    var entry: Entry!
    var newEntry: Entry?
    var group: Group!
    var entryUid: String = ""
    var people: [[Person]] = [[],[]]
    var personTypes: [String] = []
    var editingPerson = false
    var indexPathBeingEdited: IndexPath?
    var address: Address = Address(street: "", line2: "", line3: "", city: "", state: "", zip: "")
    var typeOptions = [PersonType.husband.rawValue, PersonType.wife.rawValue, PersonType.single.rawValue, PersonType.child.rawValue]
    let birthOrderOptions = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
    var birthOrders: [Int] = []
    
    var textFieldValues: [String] = []

    var currentTextField: UITextField?
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.toolbar.isTranslucent = false
        
        editAddressButton.tintColor = GlobalFunctions.shared.themeColor()
        addPersonButton.tintColor = GlobalFunctions.shared.themeColor()
        submitButton.tintColor = GlobalFunctions.shared.themeColor()
        
        addressLabel.attributedText = GlobalFunctions.shared.bold(string: "Address")
        peopleLabel.attributedText = GlobalFunctions.shared.bold(string: "People")
        self.navigationController?.navigationItem.backBarButtonItem?.title = ""
        
        addPersonView.isHidden = true
        addPersonView.isUserInteractionEnabled = false
        addPersonView.layer.cornerRadius = 5
        
        addAddressView.isHidden = true
        addAddressView.isUserInteractionEnabled = false
        addAddressView.layer.cornerRadius = 5
        
        dimView = UIView(frame:UIScreen.main.bounds)
        dimView?.backgroundColor = UIColor(white: 0.4, alpha: 0.5)
        
        peopleTableView.delegate = self
        peopleTableView.dataSource = self
        
        let f = addressTableView.frame.origin
        let s = addressTableView.frame.size
        addressTableView.frame = CGRect(x: f.x, y: f.y, width: s.width, height: 120)
        addressTableView.isScrollEnabled = false
        addressTableView.separatorStyle = .none
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))
        toolBar.barStyle = .default
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
        toolBar.items = [flex, done]
        
        typePicker = UIPickerView(frame: CGRect(x: 0, y: toolBar.frame.size.height, width: screenWidth, height: 150))
        typePicker.delegate = self
        typePicker.dataSource = self
        typePicker.showsSelectionIndicator = true
        
        let typeInputView = UIView(frame:CGRect(x: 0, y: 0, width: screenWidth, height: toolBar.frame.size.height + typePicker.frame.size.height))
        typeInputView.backgroundColor = .clear
        typeInputView.addSubview(typePicker)
        
        birthOrderPicker = UIPickerView(frame: CGRect(x: 0, y: toolBar.frame.size.height, width: screenWidth, height: 150))
        birthOrderPicker.delegate = self
        birthOrderPicker.dataSource = self
        birthOrderPicker.showsSelectionIndicator = true
        
        let birthOrderInputView = UIView(frame:CGRect(x: 0, y: 0, width: screenWidth, height: toolBar.frame.size.height + birthOrderPicker.frame.size.height))
        birthOrderInputView.backgroundColor = .clear
        birthOrderInputView.addSubview(birthOrderPicker)
        
        statePicker = UIPickerView(frame: CGRect(x: 0, y: toolBar.frame.size.height, width: screenWidth, height: 150))
        statePicker.delegate = self
        statePicker.dataSource = self
        statePicker.showsSelectionIndicator = true
        
        let stateInputView = UIView(frame:CGRect(x: 0, y: 0, width: screenWidth, height: toolBar.frame.size.height + statePicker.frame.size.height))
        stateInputView.backgroundColor = .clear
        stateInputView.addSubview(statePicker)

        let allTextFields = getTextFields(view: self.view)
        for textField in allTextFields {
            if textField == personTypeTextField {
                textField.inputView = typeInputView
            }
            if textField == birthOrderTextField {
                textField.inputView = birthOrderInputView
            }
            if textField == stateTextField {
                textField.inputView = stateInputView
            }
            textField.autocorrectionType = .no
            textField.inputAccessoryView = toolBar
        }
        
        if entryUid != "" {
        
            lastNameTextField.text = textFieldValues[0]
            homePhoneTextField.text = textFieldValues[1]
            entryEmailTextField.text = textFieldValues[2]
            
            streetTextField.text = textFieldValues[3]
            line2TextField.text = textFieldValues[4]
            line3TextField.text = textFieldValues[5]
            cityTextField.text = textFieldValues[6]
            stateTextField.text = textFieldValues[7]
            zipTextField.text = textFieldValues[8]
            
            self.title = "Edit Entry"
            submitButton.title = "SUBMIT CHANGES"
            
        } else {
            self.title = "Add Entry"
        }
        
        people[0].sort { $0.type! < $1.type! }
        people[1].sort { $0.birthOrder! < $1.birthOrder! }
        
    }
    
    func getTextFields(view: UIView) -> [UITextField] {
        var results = [UITextField]()
        for subview in view.subviews as [UIView] {
            if let textField = subview as? UITextField {
                results += [textField]
            } else {
                results += getTextFields(view: subview)
            }
        }
        return results
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == phoneTextField || textField == homePhoneTextField {
            
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = (newString as NSString).components(separatedBy: NSCharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.character(at: 0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne {
                formattedString.append("1 ")
                index += 1
            }
            if (length - index) > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            return false
            
        } else {
            return true
        }
    }
    
    @IBAction func addPersonButtonPressed(_ sender: Any) {
        addPersonButtonActions()
    }
    
    @IBAction func editAddressButtonPressed(_ sender: Any) {
        editAddressActions()
    }
    
    func editAddressActions() {
        addAddressView.isHidden = false
        
        self.view.addSubview(dimView!)
        self.view.bringSubview(toFront: dimView!)
        
        addAddressView.isHidden = false
        addAddressView.isUserInteractionEnabled = true
        self.view.bringSubview(toFront: addAddressView)
        
        streetTextField.becomeFirstResponder()
    }
    
    func dismissAddPersonView() {
        self.addPersonView.isHidden = true
        self.addPersonView.isUserInteractionEnabled = false
        dimView?.removeFromSuperview()
        firstNameTextField.text = ""
        personTypeTextField.text = ""
        birthOrderTextField.text = ""
        phoneTextField.text = ""
        emailTextField.text = ""
    }
    
    func dismissAddAddressView() {
        self.addAddressView.isHidden = true
        self.addAddressView.isUserInteractionEnabled = false
        dimView?.removeFromSuperview()
    }
    
    @IBAction func cancelPersonButtonPressed(_ sender: Any) {
        dismissAddPersonView()
    }
    
    @IBAction func submitAddressButtonPressed(_ sender: Any) {
        
        if streetTextField.text == "" &&
            line2TextField.text == "" &&
            line3TextField.text == "" &&
            cityTextField.text == "" &&
            stateTextField.text == "" &&
            zipTextField.text == "" {
        } else {
            if streetTextField.text == "" {
                displayAlert(title: "No Street", message: "A valid address must include a street.")
                return
            }
            if cityTextField.text == "" {
                displayAlert(title: "No City", message: "A valid address must include a city.")
                return
            }
            if stateTextField.text == "" {
                displayAlert(title: "No State", message: "A valid address must include a state.")
                return
            }
            if zipTextField.text == "" {
                displayAlert(title: "No Zip Code", message: "A valid address must include a zip code.")
                return
            } else if (zipTextField.text?.length)! < 5 {
                displayAlert(title: "Invalid Zip Code", message: "A zip code must be at least 5 digits long.")
                return
            }
        }
        
        dismissAddAddressView()
        addressTableView.reloadData()
    }
    
    @IBAction func cancelAddressButtonPressed(_ sender: Any) {
        dismissAddAddressView()
    }

    @IBAction func submitPersonButtonPressed(_ sender: Any) {
        
        if !validateNewPerson() {
            return
        }
        
        let name = firstNameTextField.text!
        let type = personTypeTextField.text!
        
        var phone = ""
        if phoneTextField.text! != "" {
            phone = phoneTextField.text!
        }
        
        var email = ""
        if emailTextField.text! != "" {
            email = emailTextField.text!
        }
        
        var birthOrder = 0
        if birthOrderTextField.text! != "" {
            birthOrder = Int(birthOrderTextField.text!)!
        }
        
        if editingPerson {
            
            let ip = indexPathBeingEdited!
            let uid = people[ip.section][ip.row].uid
            people[ip.section][ip.row] = Person(type: type, name: name, phone: phone, email: email, birthOrder: birthOrder, uid: uid!)
        
        } else {
            let newPerson = Person(type: type, name: name, phone: phone, email: email, birthOrder: birthOrder, uid: "")
            if type != PersonType.child.rawValue {
                people[0].insert(newPerson, at: people[0].count)
            } else {
                people[1].insert(newPerson, at: people[1].count)
            }
        }
        
        editingPerson = false
        dismissAddPersonView()
        people[0].sort { $0.type! < $1.type! }
        people[1].sort { $0.birthOrder! < $1.birthOrder! }
        peopleTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == addressTableView {
            return nil
        }
        return ["Adults", "Children"][section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == addressTableView {
            return 1
        }
        return people[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == addressTableView {
            return 1
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == addressTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell") as! AddressCell
            address.street = streetTextField.text
            address.line2 = line2TextField.text
            address.line3 = line3TextField.text
            address.city = cityTextField.text
            address.state = stateTextField.text
            address.zip = zipTextField.text
            cell.setUpCell(address: address)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell") as! PersonCell
        let person = people[indexPath.section][indexPath.row]
        cell.setUpCell(name: person.name!, type: person.type!, birthOrder: person.birthOrder!, phone: person.phone!, email: person.email!)
        return cell
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    func displayAlertAndDismiss(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if self.entryUid != "" {
                let entryVC = self.navigationController?.viewControllers[2] as! EntryViewController
                entryVC.entry = self.newEntry
            }
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: false, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {

        if textField == stateTextField {
            if textField.text != "" {
                statePicker.selectRow(GlobalFunctions.shared.getStates().index(of: textField.text!)!, inComponent: 0, animated: false)
            } else {
                statePicker.selectRow(0, inComponent: 0, animated: false)
                textField.text = GlobalFunctions.shared.getStates()[0]
            }
        }
        if textField == personTypeTextField {
            if textField.text != "" {
                typePicker.selectRow(typeOptions.index(of: textField.text!)!, inComponent: 0, animated: false)
            } else {
                typePicker.selectRow(0, inComponent: 0, animated: false)
                textField.text = typeOptions[0]
            }
        }
        if textField == birthOrderTextField {
            if textField.text != "" {
                birthOrderPicker.selectRow(birthOrderOptions.index(of: Int(textField.text!)!)!, inComponent: 0, animated: false)
            } else {
                birthOrderPicker.selectRow(0, inComponent: 0, animated: false)
                textField.text = String(describing: birthOrderOptions[0])
            }
        }
        currentTextField = textField
        textField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == statePicker {
            return GlobalFunctions.shared.getStates().count
        } else if pickerView == typePicker {
            return typeOptions.count
        } else {
            return birthOrderOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == statePicker {
            return GlobalFunctions.shared.getStates()[row]
        } else if pickerView == typePicker {
            return typeOptions[row]
        } else {
            return String(describing: birthOrderOptions[row])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == statePicker {
            stateTextField.text = GlobalFunctions.shared.getStates()[row]
        } else if pickerView == typePicker {
            personTypeTextField.text = typeOptions[row]
        } else {
            birthOrderTextField.text = String(describing: birthOrderOptions[row])
        }
        if personTypeTextField.text == PersonType.child.rawValue {
            birthOrderTextField.isEnabled = true
        } else {
            birthOrderTextField.isEnabled = false
            birthOrderTextField.text = ""
        }
    }
    
    @objc func dismissKeyboard() {
        currentTextField?.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        return cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == peopleTableView {
            let person = people[indexPath.section][indexPath.row]
            addPersonButtonActions()
            addPersonLabel.text = "Edit Person"
            if person.type == PersonType.child.rawValue {
                birthOrderTextField.isEnabled = true
                birthOrderTextField.text = String(describing: person.birthOrder!)
                for i in birthOrders {
                    if birthOrders[i] == person.birthOrder {
                        birthOrders.remove(at: i)
                        break
                    }
                }
            }
            firstNameTextField.text = person.name
            personTypeTextField.text = person.type
            emailTextField.text = person.email
            phoneTextField.text = person.phone
            
            removeFromPersonTypes(text: person.type!)
            
            editingPerson = true
            indexPathBeingEdited = indexPath
        } else if tableView == addressTableView {
            editAddressActions()
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func removeFromPersonTypes(text: String) {
        var i = 0
        for string in personTypes {
            if string == text {
                personTypes.remove(at: i)
                return
            }
            i = i + 1
        }
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
        if lastNameTextField.text == "" {
            displayAlert(title: "Missing Last Name", message: "A new entry must have a last name.")
            return
        }
        
        if people[0].count == 0 {
            displayAlert(title: "No Adults", message: "A new entry must have at least 1 adult.")
            return
        }
        
        if (homePhoneTextField.text?.length)! < 12 && (homePhoneTextField.text?.length)! > 0 {
            displayAlert(title: "Bad Phone Number", message: "Phone Numbers must be 12 characters long.")
            return
        }
        
        if people[0].count == 1 {
            if people[0][0].type == PersonType.husband.rawValue {
                displayAlert(title: "Missing Spouse", message: "A husband must have a wife.")
                return
            } else if people[0][0].type == PersonType.wife.rawValue {
                displayAlert(title: "Missing Spouse", message: "A wife must have a husband.")
                return
            }
        }
        
        var title: String!
        if self.entryUid != "" {
            title = "Edit Entry"
        } else {
            title = "Add Entry"
        }
        
        let alert = UIAlertController(title: title, message: "Are you sure you want to continue?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            let allPeople = self.people[0] + self.people[1]
            
            self.newEntry = Entry(uid: self.entryUid, name: self.lastNameTextField.text!, phone: self.homePhoneTextField.text!, email: self.entryEmailTextField.text!, address: self.address, people: allPeople)
            
            if GlobalFunctions.shared.hasConnectivity() {
                FirebaseClient.shared.addEntry(groupUid: self.group.uid, entry: self.newEntry!) { success in
                    self.defaults.setValue(true, forKey: "shouldUpdateDirectory")
                    if let success = success {
                        if success {
                            self.delegate?.updateEditedEntry(entry: self.newEntry)
                            self.displayAlertAndDismiss(title: "Success", message: "The new entry information was added to the database.")
                        } else {
                            self.displayAlert(title: "Failure", message: "The new entry information was not added to the database.")
                        }
                    }
                }
            } else {
                self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
            }
        }))

        
        self.present(alert, animated: false, completion: nil)
        
    }
    
    func validateNewPerson() -> Bool {
        
        if firstNameTextField.text! == "" {
            displayAlert(title: "No Name", message: "You must enter a first name.")
            return false
        }
        
        if personTypeTextField.text! == "" {
            displayAlert(title: "No Type", message: "Each person must have a type.")
            return false
        }
        
        if personTypeTextField.text == PersonType.child.rawValue && birthOrderTextField.text == "" {
            displayAlert(title: "Missing Birth Order", message: "Children must have a birth order.")
            return false
        }
        
        if (phoneTextField.text?.length)! < 12 && (phoneTextField.text?.length)! > 0 {
            displayAlert(title: "Bad Phone Number", message: "Phone Numbers must be 12 characters long.")
            return false
        }
        
        if personTypeTextField.text != PersonType.child.rawValue {
            if personTypes.contains(personTypeTextField.text!) {
                displayAlert(title: "Duplicate Person Type", message: "Entries can only contain one \(personTypeTextField.text!).")
                return false
            }
        }
        
        if personTypeTextField.text == PersonType.husband.rawValue || personTypeTextField.text == PersonType.wife.rawValue {
            if personTypes.contains(PersonType.single.rawValue) {
                displayAlert(title: "Error", message: "Married couples and adult Singles cannot be in the same entry.")
                return false
            }
            
        }
        
        if personTypeTextField.text == PersonType.single.rawValue {
            if personTypes.contains(PersonType.husband.rawValue) || personTypes.contains(PersonType.wife.rawValue) {
                displayAlert(title: "Error", message: "Married couples and adult Singles cannot be in the same entry.")
                return false
            }
        }
        
        if birthOrderTextField.text != "" {
            let birthOrderInt = Int(birthOrderTextField.text!)!
            if birthOrders.contains(birthOrderInt) {
                displayAlert(title: "Bad Birth Order", message: "Birth Order must be unique.")
                return false
            } else {
                birthOrders.append(birthOrderInt)
            }
        }
        personTypes.append(personTypeTextField.text!)
        return true
    }
    
    func addPersonButtonActions() {
        addPersonLabel.text = "Add Person"
        addPersonView.isHidden = false
        
        if personTypeTextField.text != PersonType.child.rawValue {
            birthOrderTextField.isEnabled = false
        }
        
        self.view.addSubview(dimView!)
        self.view.bringSubview(toFront: dimView!)
        
        addPersonView.isHidden = false
        addPersonView.isUserInteractionEnabled = true
        self.view.bringSubview(toFront: addPersonView)
        
        firstNameTextField.becomeFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == peopleTableView {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let person = people[indexPath.section][indexPath.row]
            removeFromPersonTypes(text: person.type!)
            people[indexPath.section].remove(at: indexPath.row)
            peopleTableView.reloadData()
        }
    }

}

class PersonCell: UITableViewCell {
    
    @IBOutlet weak var line1: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    
    func setUpCell(name: String, type: String, birthOrder: Int, phone: String, email: String) {
        if type != PersonType.child.rawValue {
            self.line1.text = name + ", " + type
        } else {
            var birthOrderString = "st child"
            if birthOrder == 2 {
                birthOrderString = "nd child"
            } else if birthOrder == 3 {
                birthOrderString = "rd child"
            } else if birthOrder > 3 {
                birthOrderString = "th child"
            }
            self.line1.text = name + ", " + String(describing: birthOrder) + birthOrderString
        }
        self.line2.attributedText = GlobalFunctions.shared.getFormattedString(string1: "Phone: ", string2: phone)
        self.line3.attributedText = GlobalFunctions.shared.getFormattedString(string1: "Email: ", string2: email)
    }
}

class AddressCell: UITableViewCell {
    
    @IBOutlet weak var line1: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    
    func setUpCell(address: Address) {
        
        self.line1.attributedText = GlobalFunctions.shared.getFormattedString(string1: "Street: ", string2: address.street!)
        self.line2.attributedText = GlobalFunctions.shared.getFormattedString(string1:"Line 2: ", string2: address.line2!)
        self.line3.attributedText = GlobalFunctions.shared.getFormattedString(string1:"Line 3: ", string2: address.line3!)
        var addressString: String
        if address.city!.isEmpty {
            addressString = address.state! + " " + address.zip!
        } else {
            addressString = address.city! + ", " + address.state! + " " + address.zip!
        }
        self.line4.attributedText = GlobalFunctions.shared.getFormattedString(string1:"City, State, Zip: ", string2: addressString)
        
    }
    
}

