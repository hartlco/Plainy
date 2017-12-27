//
//  Created by martin on 02.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files

protocol FileSystemItemCellDelegate: class {
    func didRenameItem(item: BrowseFileSystemItem)
}

class FileSystemItemCell: NSTableCellView {
    static let identifier = "FileCell"
    weak var delegate: FileSystemItemCellDelegate?

    private let modelController = ModelController()

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

        modelController.rename(browseItem: fileSystemItem, to: fileNameTextField.stringValue)
        delegate?.didRenameItem(item: fileSystemItem)

        return true
    }
}
