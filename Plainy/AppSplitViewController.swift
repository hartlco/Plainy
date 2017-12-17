//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Foundation
import Cocoa

class AppSplitViewController: NSSplitViewController {
    private var browseViewController: BrowseViewController?
    private var editorViewController: EditorViewController?
    private let preferencesManager: PreferencesManager = .shared

    override func viewDidLoad() {
        super.viewDidLoad()

        browseViewController = splitViewItems.first?.viewController as?BrowseViewController
        editorViewController = splitViewItems.last?.viewController as? EditorViewController

        browseViewController?.updateFiles(rootPath: preferencesManager.rootPath)

        installCallbacks()
    }

    private func installCallbacks() {
        browseViewController?.didSelectFile = { [weak self] browseFile in
            self?.editorViewController?.browseFile = browseFile
        }

        preferencesManager.didChangeRootPath = { [weak self] path in
            self?.browseViewController?.updateFiles(rootPath: path)
            self?.editorViewController?.browseFile = nil
        }

        ShortCutManager.shared.saveAction = { [weak self] in
            self?.editorViewController?.save()
            self?.browseViewController?.update(file: self?.editorViewController?.browseFile)
        }

        ShortCutManager.shared.newFileAction = { [weak self] in
            self?.browseViewController?.newFileOnSelectedFolder()
        }

        ShortCutManager.shared.newFolderAction = { [weak self] in
            self?.browseViewController?.newFolderOnSelectedFolder()
        }

        ShortCutManager.shared.deleteAction = { [weak self] in
            self?.browseViewController?.deleteSelectedFileSystemidem()
        }

        ShortCutManager.shared.presentOpenQuickly = { [weak self] in
            self?.showOpenQuickly()
        }
    }

    private func showOpenQuickly() {
        let openQuicklyStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "OpenQuickly"), bundle: nil)
        guard let viewController = openQuicklyStoryboard.instantiateInitialController() as? OpenQuicklyViewController else { return }
        presentViewControllerAsSheet(viewController)
    }
}
