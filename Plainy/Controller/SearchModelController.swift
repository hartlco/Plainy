//
//  Created by martin on 17.12.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import CoreData
import Files

class SearchModelController {
    static let shared = SearchModelController()

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "SearchModel")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()

    // MARK: - Core Data Saving and Undo support

    private func saveAction() {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = backgroundContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func terminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = backgroundContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }

        if !context.hasChanges {
            return .terminateNow
        }

        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if result {
                return .terminateCancel
            }

            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info")
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)

            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

    func index() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SearchModel")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        // perform the delete
        do {
            try backgroundContext.execute(deleteRequest)
            let root = try Folder(path: PreferencesManager.shared.rootPath)
            index(folder: root)
            let request: NSFetchRequest = SearchModel.fetchRequest()
            let files = try backgroundContext.fetch(request)
            print("Indexed files: \(files.count)")
        } catch {
            print("error")
        }
    }

    func updateIndex(for file: File) {
        let request: NSFetchRequest = SearchModel.fetchRequest()
        request.predicate = NSPredicate(format: "path == %@", file.path)
        let result = try? backgroundContext.fetch(request)
        result?.forEach {
            guard let newContent = try? file.readAsString() else { return }
            $0.content = newContent
        }

        print("Updated indexed")
        saveAction()
    }

    func files(containing string: String) -> [SearchModel] {
        let request: NSFetchRequest = SearchModel.fetchRequest()
        request.predicate = NSPredicate(format: "(content CONTAINS[cd] %@) OR (name CONTAINS[cd] %@)", string, string)
        let result = try? persistentContainer.viewContext.fetch(request)

        return result ?? []
    }

    func remove(fromIndex fileSystemItem: FileSystem.Item) {
        if let folder = fileSystemItem as? Folder {
            remove(fromIndex: folder)
        } else if let file = fileSystemItem as? File {
            remove(fromIndex: file)
        }
    }

    private func remove(fromIndex folder: Folder) {
        folder.subfolders.forEach {
            remove(fromIndex: $0)
        }

        folder.files.forEach {
            remove(fromIndex: $0)
        }

        saveAction()
    }

    private func remove(fromIndex file: File) {
        let request: NSFetchRequest = SearchModel.fetchRequest()
        request.predicate = NSPredicate(format: "path == %@", file.path)
        let result = try? backgroundContext.fetch(request)
        result?.forEach {
            print("Removed file \($0.path!) from index")
            backgroundContext.delete($0)
        }

        saveAction()
    }

    func index(fileSystemItem: FileSystem.Item) {
        if let folder = fileSystemItem as? Folder {
            index(folder: folder)
        } else if let file = fileSystemItem as? File {
            index(file: file)
        }
    }

    private func index(folder: Folder) {
        print("Index folder \(folder.name)")
        folder.subfolders.forEach {
            index(folder: $0)
        }

        folder.files.forEach {
            index(file: $0)
        }

        saveAction()
    }

    private func index(file: File) {
        print("Index file \(file.name)")
        let searchModel = SearchModel(context: backgroundContext)
        searchModel.path = file.path
        searchModel.content = (try? file.readAsString()) ?? ""
        searchModel.name = file.name
    }
}
