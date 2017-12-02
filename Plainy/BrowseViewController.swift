//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files
import Witness

extension Folder {
    var allItems: [FileSystem.Item] {
        let folders: [FileSystem.Item] = Array(subfolders)
        let allFiles: [FileSystem.Item] = Array(files)
        return folders + allFiles
    }

    var allItemsCount: Int {
        return subfolders.count + files.count
    }
}

extension FileSystem.Item {
    func trash() throws {
        do {
            try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
        } catch {
            throw OperationError.deleteFailed(self)
        }
    }
}

class BrowseViewController: NSViewController {
    var didSelectFile: (File?) -> () = { _ in }

    private var rootFolder = Folder.home
    private var didInsert = false

    @IBOutlet private  weak var outlineView: MenuOutlineView! {
        didSet {
            outlineView.delegate = self
            outlineView.dataSource = self
        }
    }
    
    func updateFiles(rootPath: String) {
        guard let newRootFolder = try? Folder(path: rootPath) else {
            rootFolder =  Folder.home
            return
        }
        
        rootFolder = newRootFolder
        outlineView.reloadData()
    }
    
    func update(file: File?) {
        let row = outlineView.row(forItem: file)
        outlineView.reloadData(forRowIndexes: [row], columnIndexes: [0])
    }

    @objc func newFileOnSelectedFolder() {
        let item = outlineView.item(atRow: outlineView.selectedRow)
        let folderToCreateIn: Folder

        if let file = item as? File {
            folderToCreateIn = file.parent ?? rootFolder
        } else if let folder = item as? Folder {
            folderToCreateIn = folder
        } else {
            folderToCreateIn = rootFolder
        }

        guard let newFile = try? folderToCreateIn.createFile(named: "newfile.md") else { return }
        let index = folderToCreateIn.allItems.index(of: newFile) ?? 0
        let parent: Any?
        
        if folderToCreateIn == rootFolder {
            parent = nil
        } else {
            parent = folderToCreateIn
        }
        
        didInsert = true
        outlineView.insertItems(at: [index], inParent: parent, withAnimation: .slideDown)
    }
    
    @objc func newFolderOnSelectedFolder() {
        let item = outlineView.item(atRow: outlineView.selectedRow)
        let folderToCreateIn: Folder
        
        if let file = item as? File {
            folderToCreateIn = file.parent ?? rootFolder
        } else if let folder = item as? Folder {
            folderToCreateIn = folder
        } else {
            folderToCreateIn = rootFolder
        }
        
        guard let newFile = try? folderToCreateIn.createSubfolder(named: "newfolder") else { return }
        let index = folderToCreateIn.allItems.index(of: newFile) ?? 0
        let parent: Any?
        
        if folderToCreateIn == rootFolder {
            parent = nil
        } else {
            parent = folderToCreateIn
        }
        
        didInsert = true
        outlineView.insertItems(at: [index], inParent: parent, withAnimation: .slideDown)
    }
    
    @objc func deleteSelectedFileSystemidem() {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? FileSystem.Item else { return }
        
    
        let containedFolder = (outlineView.parent(forItem: item) as? Folder) ?? rootFolder

        let parent: Any?

        if containedFolder == rootFolder {
            parent = nil
        } else {
            parent = containedFolder
        }

        guard let index = containedFolder.allItems.index(of: item) else { return }
        try? item.trash()
        outlineView.item
        outlineView.removeItems(at: [index], inParent: parent, withAnimation: .slideUp)
        didSelectFile(nil)
    }
    
    // MARK: - Private helper

    private var addMenu: NSMenu {
        let newFileMenu = NSMenu(title: "New file")
        newFileMenu.addItem(NSMenuItem(title: "New file", action: #selector(BrowseViewController.newFileOnSelectedFolder), keyEquivalent: ""))
        newFileMenu.addItem(NSMenuItem(title: "New folder", action: #selector(BrowseViewController.newFolderOnSelectedFolder), keyEquivalent: ""))
        newFileMenu.addItem(NSMenuItem(title: "Delete", action: #selector(BrowseViewController.deleteSelectedFileSystemidem), keyEquivalent: ""))
        return newFileMenu
    }
}

extension BrowseViewController: NSOutlineViewDataSource, MenuOutlineViewDelegate {
    func outlineView(menuForNoItemIn outlineView: NSOutlineView) -> NSMenu? {
        return addMenu
    }

    func outlineView(outlineView: NSOutlineView, menuForItem item: Any) -> NSMenu? {
        return addMenu
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let _ = item as? File {
            return 0
        } else if let folder = item as? Folder {
            return folder.allItemsCount
        } else if item == nil {
            return rootFolder.allItemsCount
        }

        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let newFolder = item as? Folder else {
            return rootFolder.allItems[index]
        }

        return newFolder.allItems[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let _ = item as? File {
            return false
        } else if let _ = item as? Folder {
            return true
        }

        return false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let fileCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: FileSystemItemCell.identifier), owner: self) as? FileSystemItemCell

        if let fileSystemItem = item as? FileSystem.Item {
            fileCell?.imageView?.image = NSWorkspace.shared.icon(forFile: fileSystemItem.path)
            fileCell?.textField?.stringValue = fileSystemItem.name
            fileCell?.fileSystemItem = fileSystemItem
            
            guard let file = fileSystemItem as? File,
            let text = try? file.readAsString(),
            text != "" else {
                fileCell?.textPreviewTextField.isHidden = true
                return fileCell
            }
            
            fileCell?.textPreviewTextField.isHidden = false
            fileCell?.textPreviewTextField.stringValue = text
        }
        
        return fileCell
    }

    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return true
    }

    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return true
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        selectFile(item: item)
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if didInsert {
            didInsert = false
            outlineView.selectRowIndexes([row], byExtendingSelection: false)
            guard let item = outlineView.item(atRow: row) else { return }
            selectFile(item: item)
            outlineView.scrollRowToVisible(row)
        }
    }
    
    private func selectFile(item: Any) {
        if let file = item as? File {
            didSelectFile(file)
        }
    }
}

protocol MenuOutlineViewDelegate: NSOutlineViewDelegate {
    func outlineView(outlineView: NSOutlineView, menuForItem item: Any) -> NSMenu?

    func outlineView(menuForNoItemIn outlineView: NSOutlineView) -> NSMenu?
}

class MenuOutlineView: NSOutlineView {
    override func menu(for event: NSEvent) -> NSMenu? {
        guard let delegate = delegate as? MenuOutlineViewDelegate else { return nil }

        let point = convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)
        let item = self.item(atRow: row)

        selectRowIndexes([row], byExtendingSelection: false)

        if (item == nil) {
            deselectAll(nil)
            return delegate.outlineView(menuForNoItemIn: self)
        }

        return delegate.outlineView(outlineView: self, menuForItem: item!)
    }
}
