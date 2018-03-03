//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files
import CoreData

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
//        NSApplication.shared.mainWindow?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        SearchModelController.shared.index()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return SearchModelController.shared.terminate(sender)
    }

    // MARK: - Shortcuts

    @IBAction func newFile(_ sender: Any) {
        keyWindowController.shortCutManager.newFileAction?()
    }

    @IBAction func newFolder(_ sender: Any) {
        keyWindowController.shortCutManager.newFolderAction?()
    }

    @IBAction func save(_ sender: Any) {
        keyWindowController.shortCutManager.saveAction?()
    }

    @IBAction func deleteAction(_ sender: Any) {
        keyWindowController.shortCutManager.deleteAction?()
    }

    @IBAction func openQuicklyAction(_ sender: Any) {
        keyWindowController.shortCutManager.presentOpenQuickly?()
    }

    @IBAction func newTab(_ sender: Any) {
        keyWindowController.shortCutManager.newTab?()
    }

    private var keyWindowController: MainWindowController {
        guard let controller = NSApplication.shared.keyWindow?.windowController as? MainWindowController else {
            fatalError("WindowController is now MainWindowController")
        }

        return controller
    }
}

class ShortCutManager {
    var saveAction: (() -> Void)?
    var newFileAction: (() -> Void)?
    var newFolderAction: (() -> Void)?
    var deleteAction: (() -> Void)?
    var presentOpenQuickly: (() -> Void)?
    var newTab:(() -> Void)?
}

class PreferencesManager {
    static let shared = PreferencesManager()

    private let userDefaults = UserDefaults.standard
    private let defaultFolderName = "Plainy"

    var didChangeRootPath: (String) -> Void = { _ in }

    var rootPath: String {
        get {
            guard let savedPath = userDefaults.string(forKey: #function) else {
                let folder = (try? Folder.home.createSubfolder(named: defaultFolderName)) ?? (try? Folder.home.subfolder(named: defaultFolderName))
                return folder!.path
            }
            return savedPath
        }

        set {
            if newValue != rootPath {
                userDefaults.set(newValue, forKey: #function)
                didChangeRootPath(newValue)
            }
        }
    }

    func resetedRootFolder() -> Folder {
        guard let folder = (try? Folder.home.createSubfolder(named: defaultFolderName)) ?? (try? Folder.home.subfolder(named: defaultFolderName)) else {
            fatalError("Default root folder could not be created")
        }
        rootPath = folder.path
        return folder
    }
}
