//
//  Created by martin on 07.01.18.
//  Copyright © 2018 Martin Hartl. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    var subview: MainWindowController?
    let shortCutManager = ShortCutManager()

    override func windowDidLoad() {
        super.windowDidLoad()
        shortCutManager.newTab = { [weak self] in
            self?.newWindowForTab(self)
        }

        guard let splitViewController = window?.contentViewController as? AppSplitViewController else {
            fatalError("Root content viewcontroller is no splitviewcontroller")
        }

        splitViewController.shortCutManager = shortCutManager
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
