import SwiftUI

public struct FilePickerViewModifier: ViewModifier {
    // MARK: Binding
    @Binding private var filePickerSource: FilePickerSource?
    
    // MARK: Properties
    private let onResult: (Result<[File], any Error>) -> Void
    private let onCancel: (() -> Void)?
    private let onStartAssetsProcessing: (() -> Void)?
    private let onEndAssetsProcessing: (() -> Void)?
    
    public init(
        filePickerSource: Binding<FilePickerSource?>,
        onResult: @escaping (Result<[File], any Error>) -> Void,
        onCancel: (() -> Void)? = nil,
        onStartAssetsProcessing: (() -> Void)? = nil,
        onEndAssetsProcessing: (() -> Void)? = nil
    ) {
        self._filePickerSource = filePickerSource
        self.onResult = onResult
        self.onCancel = onCancel
        self.onStartAssetsProcessing = onStartAssetsProcessing
        self.onEndAssetsProcessing = onEndAssetsProcessing
    }
    
    public func body(content: Content) -> some View {
        content
            .sheet(item: $filePickerSource) { filePickerSource in
                switch filePickerSource {
                case .camera(let cropMode, let compression):
                    MediaPickerView(
                        source: .camera(cropMode: cropMode, compression: compression),
                        onResult: { result in
                            self.filePickerSource = nil
                            onResult(result)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartAssetsProcessing: {
                            onStartAssetsProcessing?()
                        },
                        onEndAssetsProcessing: {
                            onEndAssetsProcessing?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .photos(let selectionLimit, let cropMode, let compression):
                    MediaPickerView(
                        source: .photos(
                            selectionLimit: selectionLimit,
                            cropMode: cropMode,
                            compression: compression
                        ),
                        onResult: { result in
                            self.filePickerSource = nil
                            onResult(result)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartAssetsProcessing: {
                            onStartAssetsProcessing?()
                        },
                        onEndAssetsProcessing: {
                            onEndAssetsProcessing?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .videos(let selectionLimit, let imageCompression):
                    MediaPickerView(
                        source: .videos(selectionLimit: selectionLimit, imageCompression: imageCompression),
                        onResult: { result in
                            self.filePickerSource = nil
                            onResult(result)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartAssetsProcessing: {
                            onStartAssetsProcessing?()
                        },
                        onEndAssetsProcessing: {
                            onEndAssetsProcessing?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .multimedia(let selectionLimit, let imageCompression):
                    MediaPickerView(
                        source: .multimedia(selectionLimit: selectionLimit, imageCompression: imageCompression),
                        onResult: { result in
                            self.filePickerSource = nil
                            onResult(result)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartAssetsProcessing: {
                            onStartAssetsProcessing?()
                        },
                        onEndAssetsProcessing: {
                            onEndAssetsProcessing?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .files(let allowMultipleSelection):
                    DocumentPickerView(
                        allowsMultipleSelection: allowMultipleSelection,
                        onSelect: { files in
                            self.filePickerSource = nil
                            onResult(.success(files))
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        }
                    )
                    .ignoresSafeArea()
                }
            }
    }
}

extension View {
    public func withFilePicker(
        source: Binding<FilePickerSource?>,
        onResult: @escaping (Result<[File], any Error>) -> Void,
        onCancel: (() -> Void)? = nil,
        onStartAssetsProcessing: (() -> Void)? = nil,
        onEndAssetsProcessing: (() -> Void)? = nil
    ) -> some View {
        modifier(FilePickerViewModifier(
            filePickerSource: source,
            onResult: onResult,
            onCancel: onCancel,
            onStartAssetsProcessing: onStartAssetsProcessing,
            onEndAssetsProcessing: onEndAssetsProcessing
        ))
    }
}
