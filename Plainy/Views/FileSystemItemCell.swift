//
//  Created by martin on 02.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files

class FileSystemItemCell: NSTableCellView {
    static let identifier = "FileCell"

    @IBOutlet weak var fileNameTextField: NSTextField!
    var fileSystemItem: BrowseFileSystemItem?
    @IBOutlet weak var textPreviewTextField: NSTextField! {
        didSet {
            textPreviewTextField.maximumNumberOfLines = 2
        }
    }
}

extension FileSystemItemCell: NSTextFieldDelegate {
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        guard let fileSystemItem = fileSystemItem else { return true }

        SearchModelController.shared.remove(fromIndex: fileSystemItem.item)
        fileSystemItem.rename(to: fileNameTextField.stringValue)
        SearchModelController.shared.index(fileSystemItem: fileSystemItem.item)

        return true
    }
}
