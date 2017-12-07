//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files
import Witness

protocol FileSystemItem {
    var item: FileSystem.Item { get }
}

class FolderItem: FileSystemItem {
    static func ==(lhs: FolderItem, rhs: FolderItem) -> Bool {
        return lhs.item.name == rhs.item.name
    }
    
    let folder: Folder
    
    var item: FileSystem.Item {
        return folder
    }
    
    lazy var allItems: [FileSystemItem] = {
        return uncachedAllItems
    }()
    
    private var uncachedAllItems: [FileSystemItem] {
        let all = folder.allItems
        let mappedItems: [FileSystemItem] = all.flatMap({ item in
            if let folderItem = item as? Folder {
                return FolderItem(folder: folderItem)
            } else if let fileItem = item as? File {
                return FileItem(file: fileItem, parent: self)
            }
            
            return nil
        })
        
        return mappedItems
    }
    
    func refreshAllItems() {
        allItems = uncachedAllItems
    }
    
    var allItemsCount: Int {
        return allItems.count
    }
    
    init(folder: Folder) {
        self.folder = folder
    }
}

class FileItem: FileSystemItem {
    let file: File
    let parent: FolderItem
    
    var item: FileSystem.Item {
        return file
    }
    
    init(file: File, parent: FolderItem) {
        self.file = file
        self.parent = parent
    }
}

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

    private var rootFolderItem = FolderItem(folder: Folder.home)
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
            rootFolderItem =  FolderItem(folder: Folder.home)
            return
        }
        
        rootFolderItem = FolderItem(folder: newRootFolder)
        outlineView.reloadData()
    }
    
    func update(file: File?) {
        let row = outlineView.row(forItem: file)
        outlineView.reloadData(forRowIndexes: [row], columnIndexes: [0])
    }

    @objc func newFileOnSelectedFolder() {
        let item = outlineView.item(atRow: outlineView.selectedRow)
        let folderToCreateIn: FolderItem

        if let file = item as? FileItem {
            folderToCreateIn = file.parent
        } else if let folder = item as? FolderItem {
            folderToCreateIn = folder
        } else {
            folderToCreateIn = rootFolderItem
        }

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
        let folderToCreateIn: FolderItem
        
        if let _ = item as? FileItem {
            folderToCreateIn = (outlineView.parent(forItem: item) as? FolderItem) ?? rootFolderItem
        } else if let folder = item as? FolderItem {
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
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? FileSystemItem else { return }
        
    
        let containedFolder = (outlineView.parent(forItem: item) as? FolderItem) ?? rootFolderItem

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
        if let _ = item as? FileItem {
            return 0
        } else if let folder = item as? FolderItem {
            return folder.allItemsCount
        } else if item == nil {
            return rootFolderItem.allItemsCount
        }

        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let newFolder = item as? FolderItem else {
            return rootFolderItem.allItems[index]
        }

        return newFolder.allItems[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let _ = item as? FileItem {
            return false
        } else if let _ = item as? FolderItem {
            return true
        }

        return false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let fileCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: FileSystemItemCell.identifier), owner: self) as? FileSystemItemCell

        if let fileSystemItem = item as? FileSystemItem {
            fileCell?.imageView?.image = NSWorkspace.shared.icon(forFile: fileSystemItem.item.path)
            fileCell?.textField?.stringValue = fileSystemItem.item.name
            fileCell?.fileSystemItem = fileSystemItem.item
            
            guard let file = fileSystemItem as? FileItem,
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
        }
    }
    
    // MARK: - Drag n Drop
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let file = item as? FileSystemItem else { return nil }
        outlineView.selectRowIndexes([outlineView.row(forItem: item)], byExtendingSelection: false)
        
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(file.item.path, forType: .fileURL)
        return pasteboardItem
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if item == nil {
            return .move
        } else if item is FolderItem {
            return .move
        }
        
        return NSDragOperation(rawValue: 0)
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        var destinationFolder: FolderItem?
        
        if item == nil {
            destinationFolder = rootFolderItem
        } else if let itemFolder = item as? FolderItem {
            destinationFolder = itemFolder
        } else {
            destinationFolder = nil
        }
        
        guard let folder = destinationFolder,
            let file = outlineView.item(atRow: outlineView.selectedRow) as? FileSystemItem else { return false }
        
        var parent: FolderItem? = outlineView.parent(forItem: file) as? FolderItem ?? rootFolderItem
        
        do {
            let oldIndex = parent?.folder.allItems.index(of: file.item)
            try file.item.move(to: folder.folder)
            let newIndex = folder.folder.allItems.index(of: file.item)

            if let parentFolder = parent, parentFolder == rootFolderItem {
                parent = nil
            }

            if let destination = destinationFolder, destination == rootFolderItem {
                destinationFolder = nil
            }

            outlineView.moveItem(at: oldIndex ?? 0, inParent: parent, to: newIndex ?? 0, inParent: destinationFolder)

            return true
        } catch {
            return false
        }
    }
    
    
    private func selectFile(item: Any) {
        if let file = item as? FileItem{
            didSelectFile(file.file)
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
