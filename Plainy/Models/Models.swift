//
//  Created by martin on 08.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Foundation
import Files

class BrowseFileSystemItem: Equatable {
    static func == (lhs: BrowseFileSystemItem, rhs: BrowseFileSystemItem) -> Bool {
        return lhs.item.path == rhs.item.path
    }

    var item: FileSystem.Item

    init(item: FileSystem.Item) {
        self.item = item
    }
}

class BrowseFolderItem: BrowseFileSystemItem {
    var parent: BrowseFolderItem?

    let folder: Folder

    lazy var allItems: [BrowseFileSystemItem] = {
        return uncachedAllItems
    }()

    private var uncachedAllItems: [BrowseFileSystemItem] {
        let all = folder.allItems
        let mappedItems: [BrowseFileSystemItem] = all.flatMap({ item in
            if let folderItem = item as? Folder {
                return BrowseFolderItem(folder: folderItem, parent: self)
            } else if let fileItem = item as? File {
                return BrowseFileItem(file: fileItem)
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

    init(folder: Folder, parent: BrowseFolderItem?) {
        self.folder = folder
        self.parent = parent
        super.init(item: folder)
    }
}

class BrowseFileItem: BrowseFileSystemItem {
    let file: File

    init(file: File) {
        self.file = file
        super.init(item: file)
    }
}
