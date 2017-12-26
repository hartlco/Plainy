//
//  Created by martin on 26.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Foundation

class ModelController {
    private let searchModelController: SearchModelController

    init(searchModelController: SearchModelController = .shared) {
        self.searchModelController = searchModelController
    }

    func rename(browseItem: BrowseFileSystemItem, to newFilename: String) {
        searchModelController.remove(fromIndex: browseItem.item)
        if let folderItem = browseItem as? BrowseFolderItem {
            rename(folderItem: folderItem, to: newFilename)
        } else if let fileItem = browseItem as? BrowseFileItem {
            rename(fileItem: fileItem, to: newFilename)
        }
        searchModelController.index(fileSystemItem: browseItem.item)
    }

    // MARK: - Private

    private func rename(fileItem: BrowseFileItem, to newFilename: String) {
        try? fileItem.item.rename(to: newFilename)
    }

    private func rename(folderItem: BrowseFolderItem, to newFilename: String) {
        try? folderItem.item.rename(to: newFilename)
        folderItem.refreshAllItems()
    }
}
