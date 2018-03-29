//
//  Created by martin on 17.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import CoreData
import Files

class SearchModelController {
    static let shared = SearchModelController()

    func files(containing string: String, in folder: Folder) -> [SearchModel] {
        var models = [SearchModel]()

        folder.subfolders.forEach {
            models += files(containing: string, in: $0)
        }

        folder.files.forEach {
            guard let fileContent = try? $0.readAsString().lowercased() else { return }

            if $0.name.contains(string.lowercased()) {
                models.append(SearchModel(content: fileContent, name: $0.name, path: $0.path))
            } else if fileContent.contains(string) {
                models.append(SearchModel(content: fileContent, name: $0.name, path: $0.path))
            }
        }

        return models
    }
}

struct SearchModel {
    let content: String
    let name: String
    let path: String
}
