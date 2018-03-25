//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files
import CodeTextEditor

class EditorViewController: NSViewController {
    var shortCutManager: ShortCutManager?

    private let fileSaveController = FileSaveController.shared

    var browseFile: BrowseFileItem? {
        didSet {
            guard let browseFile = browseFile,
                let data = try? browseFile.file.readAsString() else {
                codeView.string = ""
                return
            }

            guard codeView.string as String != data else { return }
            editorView.applySyntax(for: browseFile.item.name)
            codeView.string = data
        }
    }

    private let notificationCenter: NotificationCenter = .default

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.saveOnLoosingFocus), name: NSWindow.didResignKeyNotification, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc private func saveOnLoosingFocus() {
        shortCutManager?.saveAction!()
    }

    func save() {
        guard let browseFileItem = browseFile else { return }
        fileSaveController.save(input: codeView.string, to: browseFileItem)
    }

    @IBOutlet weak var container: NSView!

    var codeView: EditorTextView! {
        return editorView.textView!
    }

    private var editorView: CodeTextEditor.EditorViewController {
        guard let editorViewController = childViewControllers.first as? CodeTextEditor.EditorViewController else {
            fatalError()
        }
        return editorViewController
    }
}

extension EditorViewController: NSTextViewDelegate {
    func textDidEndEditing(_ notification: Notification) {
        shortCutManager?.saveAction!()
    }
}
