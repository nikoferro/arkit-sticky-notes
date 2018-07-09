//
//  AddNoteViewController.swift
//  sticky
//
//  Created by Nicolas Ferro on 02/07/2018.
//  Copyright © 2018 Nicolas Ferro. All rights reserved.
//

import UIKit
import SceneKit

class AddNoteViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var noteInput: UITextView!
    @IBOutlet weak internal var footer: UIView!
    
    @IBOutlet weak var footerBottom: NSLayoutConstraint!
    
    var noteText = String()
    var placeholderColor = UIColor.gray.withAlphaComponent(0.35)
    
    @IBAction func cancelButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if (presentingViewController as? ViewController) != nil {
            self.dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func confirmButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if let presenter = presentingViewController as? ViewController {
            self.dismiss(animated: true, completion:{ presenter.onNoteAdded(title: self.titleInput.text!, note: self.noteInput.text) })
        }
    }
    override func viewDidLoad() {
        self.titleInput.delegate = self
        self.noteInput.delegate = self
        self.setInputStyles()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AddNoteViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddNoteViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    func setInputStyles() {
//        self.confirmButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 30)
//        self.confirmButton.setTitle(String.fontAwesomeIcon(name: .plusSquareO), for: .normal)
        self.confirmButton.backgroundColor = UIColor(hexString: "#F5D841")
        self.confirmButton.tintColor = UIColor(hexString: "#ffffff")
        self.confirmButton.layer.cornerRadius = 5
        self.confirmButton.clipsToBounds = true
        
        self.cancelButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 30)
        self.cancelButton.setTitle(String.fontAwesomeIcon(name: .angleLeft), for: .normal)
        self.cancelButton.tintColor = UIColor(hexString: "#F5D841")
        
        self.footer.backgroundColor = UIColor(hexString: "#ffffff")
        
        self.titleInput.returnKeyType = UIReturnKeyType.done
        
        self.titleInput.attributedPlaceholder = NSAttributedString(string: "Note Title", attributes:[NSAttributedStringKey.foregroundColor: placeholderColor])
        
        self.noteInput.text = "Note Text"
        self.noteInput.textColor = placeholderColor
        
        self.noteInput.layer.cornerRadius = 5
        self.noteInput.layer.borderColor = UIColor.gray.withAlphaComponent(0.25).cgColor
        self.noteInput.layer.borderWidth = 0.5
        self.noteInput.clipsToBounds = true
        self.noteInput.contentInset = UIEdgeInsets(top: 0, left: 2.25, bottom: 0, right: 2.25)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("RETURN GO HIT")
        self.noteText = textField.text!
        textField.resignFirstResponder()
        return false
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
        print(self.footer.frame.origin.y)
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if footerBottom.constant == 0 {
                footerBottom.constant = keyboardSize.height
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
        print(self.footer.frame.origin.y)
        if ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            footerBottom.constant = 0
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.noteInput.textColor = .black
        if(self.noteInput.text == "Note Text") {
            self.noteInput.text = ""
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if(textView.text == "") {
            self.noteInput.text = "Note Text"
            self.noteInput.textColor = placeholderColor
        }
    }
}
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
