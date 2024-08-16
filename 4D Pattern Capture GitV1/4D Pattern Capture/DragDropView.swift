//
//  DragDropView.swift
//  4D Pattern Capture
//
//  Created by Taylor Hinchliffe on 2/28/24.
//

import Foundation
import Cocoa

protocol DragDropViewDelegate: AnyObject {
    func didExtractImages(_ images: [NSImage])
    func didExtractVideo(_ videoURL: URL)  // Add this new method
}

class DragDropView: NSView {
    
    weak var delegate: DragDropViewDelegate?
    
    private var message: String = ""
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        // Register for file URLs
        registerForDraggedTypes([.fileURL])
        
        // Set the default message
        self.message = "Drag video file here."
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard // Directly access the pasteboard

        // Ensure the pasteboard contains file URLs and check if they are video files
        if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           fileUrls.allSatisfy({ $0.pathExtension.lowercased() == "mov" || $0.pathExtension.lowercased() == "mp4" }) {
            return .copy
        } else {
            return []
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard // Directly access the pasteboard

        // Attempt to read file URLs from the pasteboard
        if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in fileUrls {
                handleVideoFile(url) // Process each video file URL
            }
            return true
        } else {
            return false
        }
    }
    
    private func handleVideoFile(_ url: URL) {
        print("Handling video file: \(url)")  // Debugging statement
        DispatchQueue.global(qos: .userInitiated).async {
            // Notify the delegate with the video URL
            DispatchQueue.main.async {
                self.delegate?.didExtractVideo(url)
            }
        }
    }

    private func updateMessage(_ newMessage: String) {
        DispatchQueue.main.async { [weak self] in
            self?.message = newMessage
            self?.needsDisplay = true // Trigger a redraw of the view
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
        if !message.isEmpty {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: NSColor.white
            ]
            
            let string = NSAttributedString(string: message, attributes: attrs)
            string.draw(in: CGRect(x: 0, y: bounds.midY - 10, width: bounds.width, height: 30))
        }
    }
}
