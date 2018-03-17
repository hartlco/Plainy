//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files

class BrowseViewController: NSViewController {
    var didSelectFile: (BrowseFileItem?) -> Void = { _ in }

    lazy private var rootFolderItem: BrowseFolderItem = {
        guard let folder = try? Folder(path: PreferencesManager.shared.rootPath) else {
            return BrowseFolderItem(folder: PreferencesManager.shared.resetedRootFolder(), parent: nil)
        }
        return BrowseFolderItem(folder: folder, parent: nil)
    }()
    private var didInsert = false
    private var draggedItem: BrowseFileSystemItem?
    private var expandedItemPaths: Set<String> = []

    @IBOutlet private(set)  weak var outlineView: MenuOutlineView! {
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

    func refresh() {
        let oldSelectedItem = outlineView.item(atRow: outlineView.selectedRow)

        rootFolderItem.refreshAllItems()
        outlineView.reloadData()
        for path in expandedItemPaths {
            expand(at: path)
        }

        if let item = oldSelectedItem as? BrowseFileItem {
            select(at: item.item.path)
        }
    }

    func update(file: BrowseFileItem?) {
        guard let file = file else { return }

        outlineView.reloadItem(file)
    }

    func select(at path: String) {
        let itemsToExpand = rootFolderItem.itemsToExpand(at: path)
        for item in itemsToExpand {
            if item is BrowseFolderItem {
                outlineView.expandItem(item)
            } else {
                let row = outlineView.row(forItem: item)
                outlineView.selectRowIndexes([row], byExtendingSelection: false)
                selectFile(item: item)
                return
            }
        }

        selectFile(item: nil)
    }

    func expand(at path: String) {
        let itemsToExpand = rootFolderItem.itemsToExpand(at: path)
        outlineView.expandItem(itemsToExpand.last)
    }

    @objc func newFileOnSelectedFolder() {
        let item = outlineView.item(atRow: outlineView.selectedRow)
        let folderToCreateIn: BrowseFolderItem

        if item is BrowseFileItem {
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

        if item is BrowseFileItem {
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

        guard let index = containedFolder.allItems.index(of: item) else { return }
        try? item.item.trash()
        containedFolder.refreshAllItems()
        outlineView.item
        outlineView.removeItems(at: [index], inParent: parent, withAnimation: .slideUp)
        didSelectFile(nil)
    }

    @objc func openSelectedFileInFinder() {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? BrowseFileSystemItem else { return }

        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.item.path)])
    }

    // MARK: - Private helper

    private var addMenu: NSMenu {
        let newFileMenu = NSMenu(title: "New file")
        newFileMenu.addItem(NSMenuItem(title: "New file",
                                       action: #selector(BrowseViewController.newFileOnSelectedFolder), keyEquivalent: ""))
        newFileMenu.addItem(NSMenuItem(title: "New folder",
                                       action: #selector(BrowseViewController.newFolderOnSelectedFolder), keyEquivalent: ""))
        newFileMenu.addItem(NSMenuItem(title: "Delete",
                                       action: #selector(BrowseViewController.deleteSelectedFileSystemidem), keyEquivalent: ""))
        newFileMenu.addItem(NSMenuItem(title: "Open in Finder",
                                       action: #selector(BrowseViewController.openSelectedFileInFinder), keyEquivalent: ""))
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
        if item is BrowseFileItem {
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
        if item is BrowseFileItem {
            return false
        } else if item is BrowseFolderItem {
            return true
        }

        return false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let fileCell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: FileSystemItemCell.identifier),
                                            owner: self) as? FileSystemItemCell

        if let fileSystemItem = item as? BrowseFileSystemItem {
            fileCell?.imageView?.image = NSWorkspace.shared.icon(forFile: fileSystemItem.item.path)
            fileCell?.textField?.stringValue = fileSystemItem.item.name
            fileCell?.fileSystemItem = fileSystemItem
            fileCell?.delegate = self

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
        }
    }

    // MARK: - Drag n Drop

    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let file = item as? BrowseFileSystemItem else { return nil }
        outlineView.selectRowIndexes([outlineView.row(forItem: item)], byExtendingSelection: false)

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(file.item.path, forType: .fileURL)
        return pasteboardItem
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo,
                     proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if item == nil {
            return .move
        } else if item is BrowseFolderItem {
            return .move
        }

        return NSDragOperation(rawValue: 0)
    }

    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession,
                     willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        guard let firstItem = draggedItems.first as? BrowseFileSystemItem else { return }
        draggedItem = firstItem
    }

    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession,
                     endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggedItem = nil
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo,
                     item: Any?, childIndex index: Int) -> Bool {
        let destinationBrowseFolderItem = (item as? BrowseFolderItem) ?? rootFolderItem
        if let selectedBrowseFileSystemitem = draggedItem {
             return acceptInternalDrop(inDestination: destinationBrowseFolderItem,
                                       selectedBrowseFileSystemitem: selectedBrowseFileSystemitem, childIndex: index)
        }

        return acceptExternalDrop(inDestination: destinationBrowseFolderItem, info: info, childIndex: index)
    }

    private func acceptInternalDrop(inDestination destinationBrowseFolderItem: BrowseFolderItem,
                                    selectedBrowseFileSystemitem: BrowseFileSystemItem, childIndex index: Int) -> Bool {
        selectFile(item: nil)
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

        guard let newIndex = selectedBrowseFileSystemitem.move(to: destinationBrowseFolderItem) else { return false }
        outlineView.collapseItem(selectedBrowseFileSystemitem, collapseChildren: true)
        outlineView.moveItem(at: oldIndex, inParent: parentBrowseItem, to: newIndex, inParent: moveDestinationBrowseItem)

        return true
    }

    private func acceptExternalDrop(inDestination destinationBrowseFolderItem: BrowseFolderItem,
                                    info: NSDraggingInfo, childIndex index: Int) -> Bool {
        guard let url = NSURL(from: info.draggingPasteboard()) as URL?,
            let file = try? File(path: url.path) else { return false }

        do {
            try file.copy(to: destinationBrowseFolderItem.folder)
            destinationBrowseFolderItem.refreshAllItems()
            outlineView.reloadData()
            selectFile(item: nil)

            return true
        } catch {
            return false
        }
    }

    private func selectFile(item: Any?) {
        if let file = item as? BrowseFileItem {
            didSelectFile(file)
        } else {
            didSelectFile(nil)
        }
    }
}

extension BrowseViewController: FileSystemItemCellDelegate {
    func didRenameItem(item: BrowseFileSystemItem) {
        outlineView.reloadItem(item, reloadChildren: true)
    }
}

extension BrowseViewController {
    func outlineViewItemDidExpand(_ notification: Notification) {
        guard let item = notification.userInfo?["NSObject"] as? BrowseFolderItem else { return }
        expandedItemPaths.insert(item.item.path)
    }

    func outlineViewItemDidCollapse(_ notification: Notification) {
        guard let item = notification.userInfo?["NSObject"] as? BrowseFolderItem else { return }
        expandedItemPaths.remove(item.item.path)
    }
}
