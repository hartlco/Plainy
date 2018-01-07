//
//  Created by martin on 07.01.18.
//  Copyright © 2018 Martin Hartl. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    var subview: MainWindowController?

    override func windowDidLoad() {
        super.windowDidLoad()
        ShortCutManager.shared.newTab = { [weak self] in
            self?.newWindowForTab(self)
        }
    }

    @IBAction override func newWindowForTab(_ sender: Any?) {
        guard let newWindowViewController = storyboard?.instantiateInitialController() as? MainWindowController,
         let newWindowViewControllerWindow = newWindowViewController.window else { return }

        window?.addTabbedWindow(newWindowViewControllerWindow, ordered: .above)
        self.subview = newWindowViewController

        newWindowViewController.window?.orderFront(self.window)
        newWindowViewController.window?.makeKey()
    }

}
