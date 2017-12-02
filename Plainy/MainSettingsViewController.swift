//
//  Created by martin on 02.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa

class MainSettingsViewController: NSViewController {
    @IBOutlet private weak var pathTextField: NSTextField!
    private let preferencesManager: PreferencesManager = .shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pathTextField.stringValue = preferencesManager.rootPath
    }
    
    @IBAction private func applyNowButtonPressed(_ sender: Any) {
        preferencesManager.rootPath = pathTextField.stringValue
    }
}

extension MainSettingsViewController: NSTextFieldDelegate { }
