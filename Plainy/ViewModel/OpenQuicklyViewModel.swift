//
//  Created by Martin Hartl on 30.03.18.
//  Copyright © 2018 Martin Hartl. All rights reserved.
//

import Foundation
import Files

final class OpenQuicklyViewModel {
    var searchText = "" {
        didSet {
            search(for: searchText)
        }
    }

    var resultsChanged: (() -> Void)?

    private let rootFolder: Folder
    private let searchModelController: SearchModelController
    private var results = [SearchModel]()

    init(rootFolder: Folder,
         searchModelController: SearchModelController = .shared) {
        self.rootFolder = rootFolder
        self.searchModelController = searchModelController
    }

    private func search(for text: String) {
        results = searchModelController.files(containing: text, in: rootFolder)
        resultsChanged?()
    }

    var numberOfResults: Int {
        return results.count
    }

    subscript(row: Int) -> SearchModel {
        return results[row]
    }
}
