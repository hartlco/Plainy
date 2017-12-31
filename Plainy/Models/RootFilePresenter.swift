//
//  Created by martin on 31.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa

class RootFilePresenter: NSObject, NSFilePresenter {
    static let sharedInstance = RootFilePresenter(rootFolderPath: PreferencesManager.shared.rootPath)
    var rootFolderWasUpdated: () -> Void = { }

    var presentedItemURL: URL? {
        return URL(fileURLWithPath: rootFolderPath)
    }

    var presentedItemOperationQueue: OperationQueue {
        return OperationQueue.main
    }

    private let rootFolderPath: String

    init(rootFolderPath: String) {
        self.rootFolderPath = rootFolderPath
        super.init()
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }

    @objc func presentedSubitemDidAppear(at url: URL) {
        print("did appear")
    }

    @objc func presentedSubitemDidChange(at url: URL) {
        print("did update")
        // Todo: Stupid hack to only update whole ui for changes that were made while app was not in focus
        // This callbacks need to get way more detailed and the App needs to be able to refresh it's state without closing all folders etc.
        if !NSRunningApplication.current.isActive {
            rootFolderWasUpdated()
        }
    }

    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) {
        print("did move to \(newURL)")
    }
}
