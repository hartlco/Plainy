//
//  Created by martin on 08.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Foundation
import Files

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

    var url: URL {
        return URL(fileURLWithPath: path)
    }
}
