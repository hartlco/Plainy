//
//  Created by martin on 17.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Carbon.HIToolbox
import CoreData
import Files

class OpenQuicklyViewController: NSViewController {
    lazy private var rootFolderItem: BrowseFolderItem = {
        guard let folder = try? Folder(path: PreferencesManager.shared.rootPath) else {
            return BrowseFolderItem(folder: PreferencesManager.shared.resetedRootFolder(), parent: nil)
        }
        return BrowseFolderItem(folder: folder, parent: nil)
    }()

    @IBOutlet private weak var tableView: NSTableView! {
        didSet {
            tableView.doubleAction = #selector(openFile)
        }
    }

    @IBOutlet private weak var textField: NSTextField!

    private var results: [SearchModel] = []

    var didSelectFile: (SearchModel) -> Void = { _ in }

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_Escape:
            dismiss(nil)
        case kVK_Return:
            openFile()
        case kVK_DownArrow, kVK_UpArrow:
            tableView.keyDown(with: event)
        default:
            textField.becomeFirstResponder()
            super.keyDown(with: event)
        }
    }

    @objc func openFile() {
        guard tableView.selectedRow > -1 else { return }
        didSelectFile(results[tableView.selectedRow])
        dismiss(nil)
    }
}

extension OpenQuicklyViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        results = SearchModelController.shared.files(containing: textField.stringValue, in: rootFolderItem.folder)
        tableView.reloadData()
        print("Found \(results.count) results")
        if results.count > 0 {
            tableView.selectRowIndexes([0], byExtendingSelection: false)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        dismiss(nil)
    }
}

extension OpenQuicklyViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let openCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: OpenQuicklyCell.identifier),
                                          owner: self) as? OpenQuicklyCell
        let result = results[row]
        openCell?.fileNameLabel.stringValue = result.name
        openCell?.filePreviewLabel.stringValue = result.content
        return openCell
    }
}
