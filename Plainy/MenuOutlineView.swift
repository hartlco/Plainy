//
//  Created by martin on 09.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa

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

        if item == nil {
            deselectAll(nil)
            return delegate.outlineView(menuForNoItemIn: self)
        }

        return delegate.outlineView(outlineView: self, menuForItem: item!)
    }
}
