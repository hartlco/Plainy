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
        browseViewController?.didSelectFile = { [weak self] file in
            self?.editorViewController?.file = file
        }
        
        preferencesManager.didChangeRootPath = { [weak self] path in
            self?.browseViewController?.updateFiles(rootPath: path)
            self?.editorViewController?.file = nil
        }
        
        ShortCutManager.shared.saveAction = { [weak self] in
            self?.editorViewController?.save()
            self?.browseViewController?.update(file: self?.editorViewController?.file)
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
    }

}
