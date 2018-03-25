//
//  Created by martin on 25.03.18.
//  Copyright © 2018 Martin Hartl. All rights reserved.
//

import Foundation

final class FileSaveController {
    static let shared = FileSaveController()

    private let searchModelController: SearchModelController

    init(searchModelController: SearchModelController = .shared) {
        self.searchModelController = searchModelController
    }

    func save(input: String, to fileItem: BrowseFileItem) {
        let coordinator = NSFileCoordinator(filePresenter: RootFilePresenter.sharedInstance)
        coordinator.coordinate(writingItemAt: fileItem.file.url, options: [], error: nil) { _ in
            try? fileItem.file.write(string: input)
        }

        searchModelController.updateIndex(for: fileItem.file)
    }
}
