//
//  Created by martin on 17.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Carbon.HIToolbox
import CoreData

class OpenQuicklyViewController: NSViewController {
    @IBOutlet weak var textField: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == kVK_Escape else {
            super.keyDown(with: event)
            return
        }

        dismiss(nil)
    }
}

extension OpenQuicklyViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        let results = SearchModelController.shared.files(containing: textField.stringValue)
        print("Found \(results.count) results")
    }

    override func cancelOperation(_ sender: Any?) {
        dismiss(nil)
    }
}
