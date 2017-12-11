//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func newFile(_ sender: Any) {
        ShortCutManager.shared.newFileAction?()
    }

    @IBAction func newFolder(_ sender: Any) {
        ShortCutManager.shared.newFolderAction?()
    }

    @IBAction func save(_ sender: Any) {
        ShortCutManager.shared.saveAction?()
    }

    @IBAction func deleteAction(_ sender: Any) {
        ShortCutManager.shared.deleteAction?()
    }
}

class ShortCutManager {
    static let shared = ShortCutManager()

    var saveAction: (() -> Void)?
    var newFileAction: (() -> Void)?
    var newFolderAction: (() -> Void)?
    var deleteAction: (() -> Void)?
}

class PreferencesManager {
    static let shared = PreferencesManager()

    private let userDefaults = UserDefaults.standard

    var didChangeRootPath: (String) -> Void = { _ in }

    var rootPath: String {
        get {
            guard let savedPath = userDefaults.string(forKey: #function) else { return Folder.home.path }
            return savedPath
        }

        set {
            if newValue != rootPath {
                userDefaults.set(newValue, forKey: #function)
                didChangeRootPath(newValue)
            }
        }
    }
}
