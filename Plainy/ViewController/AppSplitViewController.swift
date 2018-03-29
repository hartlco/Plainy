//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Foundation
import Cocoa
import Files

class AppSplitViewController: NSSplitViewController {
    var shortCutManager: ShortCutManager? {
        didSet {
            installCallbacks()
        }
    }

    private var browseViewController: BrowseViewController?
    private var editorViewController: EditorViewController?
    private let preferencesManager: PreferencesManager = .shared
    private let searchModelController: SearchModelController = .shared

    private var rootFilePresenter: RootFilePresenter?

    override func viewDidLoad() {
        super.viewDidLoad()

        browseViewController = splitViewItems.first?.viewController as?BrowseViewController
        editorViewController = splitViewItems.last?.viewController as? EditorViewController

        browseViewController?.updateFiles(rootPath: preferencesManager.rootPath)

        installRootFilePresenterCallbacks()

        installCallbacks()
    }

    private func installCallbacks() {
        editorViewController?.shortCutManager = shortCutManager

        browseViewController?.didSelectFile = { [weak self] browseFile in
            self?.editorViewController?.save()
            self?.editorViewController?.browseFile = browseFile
            self?.view.window?.title = browseFile?.item.name ?? "Plainy"
        }

        preferencesManager.didChangeRootPath = { [weak self] path in
            self?.browseViewController?.updateFiles(rootPath: path)
            self?.editorViewController?.browseFile = nil
            self?.installRootFilePresenterCallbacks()
        }

        shortCutManager?.saveAction = { [weak self] in
            self?.editorViewController?.save()
            self?.browseViewController?.update(file: self?.editorViewController?.browseFile)
        }

        shortCutManager?.newFileAction = { [weak self] in
            self?.browseViewController?.newFileOnSelectedFolder()
        }

        shortCutManager?.newFolderAction = { [weak self] in
            self?.browseViewController?.newFolderOnSelectedFolder()
        }

        shortCutManager?.deleteAction = { [weak self] in
            self?.browseViewController?.deleteSelectedFileSystemidem()
        }

        shortCutManager?.presentOpenQuickly = { [weak self] in
            self?.showOpenQuickly()
        }

        shortCutManager?.focusFileBrowser = { [weak self] in
            guard let weakSelf = self, let browse = weakSelf.browseViewController, let editor = weakSelf.editorViewController else { return }

            let newResponder = weakSelf.view.window?.firstResponder == browse.outlineView ? editor.codeView : browse.outlineView
            weakSelf.view.window?.makeFirstResponder(newResponder)
        }
    }

    private func showOpenQuickly() {
        let openQuicklyStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "OpenQuickly"), bundle: nil)
        guard let viewController = openQuicklyStoryboard.instantiateInitialController() as? OpenQuicklyViewController else { return }

        viewController.didSelectFile = didSelectFromOpening(searchFile:)

        presentViewControllerAsSheet(viewController)
    }

    private func didSelectFromOpening(searchFile: SearchModel) {
        browseViewController?.select(at: searchFile.path)
    }

    private func installRootFilePresenterCallbacks() {
        rootFilePresenter = RootFilePresenter(rootFolderPath: preferencesManager.rootPath)
        rootFilePresenter?.rootFolderWasUpdated = { [weak self] url in
            guard let strongSelf = self,
            strongSelf.editorViewController?.browseFile?.item.url != url else { return }
            strongSelf.browseViewController?.refresh()
        }
    }
}
