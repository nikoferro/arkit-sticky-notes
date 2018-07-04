//
//  AddNoteViewController.swift
//  sticky
//
//  Created by Nicolas Ferro on 02/07/2018.
//  Copyright © 2018 Nicolas Ferro. All rights reserved.
//

import UIKit
import SceneKit

class AddNoteViewController: UIViewController {
    @IBOutlet weak var noteInput: UITextView!
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        if let presenter = presentingViewController as? ViewController {
            presenter.noteText = noteInput.text
            self.dismiss(animated: true, completion: presenter.onClosedModalPromptForNote)
        }
    }
    override func viewDidLoad() {
        noteInput.returnKeyType = UIReturnKeyType.done
    }
}
