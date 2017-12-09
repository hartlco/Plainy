//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files
import Witness

class BrowseViewController: NSViewController {
    var didSelectFile: (BrowseFileItem?) -> () = { _ in }

    private var rootFolderItem = BrowseFolderItem(folder: Folder.home, parent: nil)
    private var didInsert = false

    @IBOutlet private  weak var outlineView: MenuOutlineView! {
        didSet {
            outlineView.delegate = self
            outlineView.dataSource = self
            outlineView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        }
    }
    
    func updateFiles(rootPath: String) {
        guard let newRootFolder = try? Folder(path: rootPath) else {
            rootFolderItem =  BrowseFolderItem(folder: Folder.home, parent: nil)
            return
        }
        
        rootFolderItem = BrowseFolderItem(folder: newRootFolder, parent: nil)
        outlineView.reloadData()
    }
    
    func update(file: BrowseFileItem?) {
        outlineView.reloadItem(file)
    }

    @objc func newFileOnSelectedFolder() {
        let item = outlineView.item(atRow: outlineView.selectedRow)
        let folderToCreateIn: BrowseFolderItem

        if let _ = item as? BrowseFileItem {
            folderToCreateIn = (outlineView.parent(forItem: item) as? BrowseFolderItem) ?? rootFolderItem
        } else if let folder = item as? BrowseFolderItem {
            folderToCreateIn = folder
        } else {
            folderToCreateIn = rootFolderItem
        }

        guard !folderToCreateIn.folder.containsFile(named: "newfile.md") else { return }
        
        guard let newFile = try? folderToCreateIn.folder.createFile(named: "newfile.md") else { return }
        let index = folderToCreateIn.folder.allItems.index(of: newFile) ?? 0
        let parent: Any?
        
        folderToCreateIn.refreshAllItems()
        
        if folderToCreateIn == rootFolderItem {
            parent = nil
        } else {
            parent = folderToCreateIn
        }
        
        didInsert = true
        outlineView.insertItems(at: [index], inParent: parent, withAnimation: .slideDown)
    }
    
    @objc func newFolderOnSelectedFolder() {
        let item = outlineView.item(atRow: outlineView.selectedRow)
        let folderToCreateIn: BrowseFolderItem
        
        if let _ = item as? BrowseFileItem {
            folderToCreateIn = (outlineView.parent(forItem: item) as? BrowseFolderItem) ?? rootFolderItem
        } else if let folder = item as? BrowseFolderItem {
            folderToCreateIn = folder
        } else {
            folderToCreateIn = rootFolderItem
        }
        
        guard let newFile = try? folderToCreateIn.folder.createSubfolder(named: "newfolder") else { return }
        folderToCreateIn.refreshAllItems()
        let index = folderToCreateIn.folder.allItems.index(of: newFile) ?? 0
        let parent: Any?
        
        if folderToCreateIn == rootFolderItem {
            parent = nil
        } else {
            parent = folderToCreateIn
        }
        
        didInsert = true
        outlineView.insertItems(at: [index], inParent: parent, withAnimation: .slideDown)
    }
    
    @objc func deleteSelectedFileSystemidem() {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? BrowseFileSystemItem else { return }
        
    
        let containedFolder = (outlineView.parent(forItem: item) as? BrowseFolderItem) ?? rootFolderItem

        let parent: Any?

        if containedFolder == rootFolderItem {
            parent = nil
        } else {
            parent = containedFolder
        }

        guard let index = containedFolder.folder.allItems.index(of: item.item) else { return }
        try? item.item.trash()
        containedFolder.refreshAllItems()
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
        if let _ = item as? BrowseFileItem {
            return 0
        } else if let folder = item as? BrowseFolderItem {
            return folder.allItemsCount
        } else if item == nil {
            return rootFolderItem.allItemsCount
        }

        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let newFolder = item as? BrowseFolderItem else {
            return rootFolderItem.allItems[index]
        }

        return newFolder.allItems[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let _ = item as? BrowseFileItem {
            return false
        } else if let _ = item as? BrowseFolderItem {
            return true
        }

        return false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let fileCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: FileSystemItemCell.identifier), owner: self) as? FileSystemItemCell

        if let fileSystemItem = item as? BrowseFileSystemItem {
            fileCell?.imageView?.image = NSWorkspace.shared.icon(forFile: fileSystemItem.item.path)
            fileCell?.textField?.stringValue = fileSystemItem.item.name
            fileCell?.fileSystemItem = fileSystemItem.item
            
            guard let file = fileSystemItem as? BrowseFileItem,
            let text = try? file.file.readAsString(),
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
            
            view.window?.makeFirstResponder(outlineView)
            
            if let rowView = rowView.view(atColumn: 0) as? FileSystemItemCell {
                    rowView.fileNameTextField.becomeFirstResponder()
                view.window?.makeFirstResponder(rowView.fileNameTextField)
            }
            
            view.window?.makeFirstResponder(rowView)
        }
    }
    
    // MARK: - Drag n Drop
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let file = item as? BrowseFileItem else { return nil }
        outlineView.selectRowIndexes([outlineView.row(forItem: item)], byExtendingSelection: false)
        
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(file.item.path, forType: .fileURL)
        return pasteboardItem
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if item == nil {
            return .move
        } else if item is BrowseFolderItem {
            return .move
        }
        
        return NSDragOperation(rawValue: 0)
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        
        let destinationBrowseFolderItem = (item as? BrowseFolderItem) ?? rootFolderItem
        guard let selectedBrowseFileSystemitem = outlineView.item(atRow: outlineView.selectedRow) as? BrowseFileItem else { return false }
        
        
        let parentBrowseItem: BrowseFolderItem? = {
            if let parent = outlineView.parent(forItem: selectedBrowseFileSystemitem) as? BrowseFolderItem {
                return parent
            }
            
            return nil
        }()
        
        let moveDestinationBrowseItem: BrowseFolderItem? = {
            if destinationBrowseFolderItem == rootFolderItem {
                return nil
            }
            
            return destinationBrowseFolderItem
        }()
        
        let oldIndex: Int = {
            if let parent = parentBrowseItem {
                return parent.allItems.index(of: selectedBrowseFileSystemitem) ?? 0
            }
            
            return rootFolderItem.allItems.index(of: selectedBrowseFileSystemitem) ?? 0
        }()
        
        do {
            try selectedBrowseFileSystemitem.item.move(to: destinationBrowseFolderItem.folder)
            destinationBrowseFolderItem.refreshAllItems()
            (parentBrowseItem ?? rootFolderItem).refreshAllItems()
            outlineView.moveItem(at: oldIndex, inParent: parentBrowseItem, to: destinationBrowseFolderItem.allItems.index(of: selectedBrowseFileSystemitem) ?? 0, inParent: moveDestinationBrowseItem)
            outlineView.reloadItem(destinationBrowseFolderItem)
        } catch {
            return false
        }
        
        return true
    }
    
    
    private func selectFile(item: Any) {
        if let file = item as? BrowseFileItem{
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
