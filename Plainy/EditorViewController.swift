//
//  Created by Martin Hartl on 30.11.17.
//  Copyright © 2017 Martin Hartl. All rights reserved.
//

import Cocoa
import Files

enum EditorFont {
    case menlo

    func font(with size: CGFloat) -> NSFont {
        switch self {
        case .menlo:
            return NSFont(name: "Menlo", size: size)!
        }
    }
}

class EditorViewController: NSViewController {
    var file: File? {
        didSet {
            guard let file = file,
            let data = try? file.readAsString() else {
                textView.string = ""
                view.window?.title = "Plainy"
                return
            }
            view.window?.title = "Plainy - \(file.name)"
            textView.string = data
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
        save()
    }
    
    func save() {
        guard let file = file,
        let readString = try? file.readAsString(),
        textView.string != readString  else { return }
        
        try? file.write(string: textView.string)
    }
    

    @IBOutlet private var textView: NSTextView! {
        didSet {
            textView.delegate = self
            textView.font = EditorFont.menlo.font(with: 14)
        }
    }
}

extension EditorViewController: NSTextViewDelegate {
    func textDidEndEditing(_ notification: Notification) {
        save()
    }
}

