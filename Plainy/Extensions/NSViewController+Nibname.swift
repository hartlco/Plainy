//
//  Created by martin on 30.03.18.
//  Copyright © 2018 Martin Hartl. All rights reserved.
//

import Cocoa

extension NSViewController {
    static var nibName: NSNib.Name {
        return NSNib.Name(rawValue: String(describing: self))
    }
}
