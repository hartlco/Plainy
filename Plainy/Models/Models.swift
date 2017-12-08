//
//  Created by martin on 08.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Foundation
import Files

protocol BrowseFileSystemItem {
    var item: FileSystem.Item { get }
}

class BrowseFolderItem: BrowseFileSystemItem {
    var parent: BrowseFolderItem?
    
    static func ==(lhs: BrowseFolderItem, rhs: BrowseFolderItem) -> Bool {
        return lhs.item.name == rhs.item.name
    }
    
    let folder: Folder
    
    var item: FileSystem.Item {
        return folder
    }
    
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
    }
}

class BrowseFileItem: BrowseFileSystemItem {
    let file: File
    
    var item: FileSystem.Item {
        return file
    }
    
    init(file: File) {
        self.file = file
    }
}
