import UIKit
import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    // MARK: Properties
    private let allowsMultipleSelection: Bool
    private let onSelect: ([File]) -> Void
    private let onCancel: () -> Void
    
    init(
        allowsMultipleSelection: Bool,
        onSelect: @escaping ([File]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onSelect = onSelect
        self.onCancel = onCancel
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPickerViewController = UIDocumentPickerViewController(
            forOpeningContentTypes: UTType.allTypes(),
            asCopy: true
        )
        
        documentPickerViewController.allowsMultipleSelection = allowsMultipleSelection
        documentPickerViewController.delegate = context.coordinator
        return documentPickerViewController
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}

extension DocumentPickerView {
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        // MARK: Properties
        private let parent: DocumentPickerView
        
        init(parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            Task { @MainActor in
                var files: [File] = []
                
                for url in urls {
                    guard let data = try? Data(contentsOf: url) else { continue }
                    let uniformType = UTType(tag: url.pathExtension, tagClass: .filenameExtension, conformingTo: nil)
                    
                    let otherFile = OtherFile(
                        id: UUID().uuidString,
                        url: url,
                        metadata: FileMetadata(
                            data: data,
                            size: nil,
                            uniformType: uniformType
                        )
                    )

                    let file = File(type: .file(otherFile))
                    files.append(file)
                }
                
                parent.onSelect(files)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }
    }
}
