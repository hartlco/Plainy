//
//  Created by martin on 26.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa

class OpenQuicklyCell: NSTableCellView {
    static let identifier = "OpenQuicklyCell"

    @IBOutlet weak var fileNameLabel: NSTextField!
    @IBOutlet weak var filePreviewLabel: NSTextField! {
        didSet {
            filePreviewLabel.maximumNumberOfLines = 3
        }
    }
}
