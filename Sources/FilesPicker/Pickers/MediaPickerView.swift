import SwiftUI
import UIKit
import Mantis
import PhotosUI

extension PresetFixedRatioType: Equatable {
    public static func == (lhs: PresetFixedRatioType, rhs: PresetFixedRatioType) -> Bool {
        switch (lhs, rhs) {
        case (.alwaysUsingOnePresetFixedRatio(let lhsRatio), .alwaysUsingOnePresetFixedRatio(let rhsRatio)):
            return lhsRatio == rhsRatio
        case (.canUseMultiplePresetFixedRatio(let lhsDefaultRatio), .canUseMultiplePresetFixedRatio(let rhsDefaultRatio)):
            return lhsDefaultRatio == rhsDefaultRatio
        case (.alwaysUsingOnePresetFixedRatio, _), (.canUseMultiplePresetFixedRatio, _):
            return false
        }
    }
}

public enum ImageCropMode: Equatable {
    case allowed(presetFixedRatioType: PresetFixedRatioType)
    case notAllowed
    
    var isCropAllowed: Bool {
        switch self {
        case .allowed:
            return true
            
        case .notAllowed:
            return false
        }
    }
}

public enum ImageCompression: Equatable {
    public enum Quality {
        case low
        case medium
        case high
        case original
        
        var value: Double {
            switch self {
            case .low:
                return 0.25
                
            case .medium:
                return 0.5
                
            case .high:
                return 0.75
                
            case .original:
                return 1.0
            }
        }
    }
    
    case original
    case compressed(maximumSize: CGSize = .init(width: 1920, height: 1080), quality: Quality = .medium)
}

public enum MediaPickerError: Error {
    case unableToCreateImage
    case corruptedImage
    case corruptedVideoPreviewImage
}

struct MediaPickerView: UIViewControllerRepresentable {
    enum Source: Equatable {
        /// Allows taking pictures from camera and applies selected crop mode / compression on selected image(s)
        case camera(
            cropMode: ImageCropMode,
            compression: ImageCompression = .compressed()
        )
        
        /// Allows picking photos exclusively and applies selected crop mode / compression on selected image(s)
        /// Note: If you specify the selection limit more than 1 and cropMode to `allowed` this is going to trigger an assertion
        case photos(
            selectionLimit: Int,
            cropMode: ImageCropMode,
            compression: ImageCompression = .compressed()
        )
        
        /// Allows picking videos and applies selected image compression
        /// On selected images and preview images that's extracted off selected videos
        case videos(
            selectionLimit: Int,
            imageCompression: ImageCompression = .compressed()
        )
        
        /// Allows picking multimedia (Photos / Videos) and applies selected image compression
        /// On selected images and preview images that's extracted off selected videos
        case multimedia(
            selectionLimit: Int,
            imageCompression: ImageCompression = .compressed()
        )
    }
    
    // MARK: Environment
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: Properties
    private let source: Source
    private let cropMode: ImageCropMode
    private let compression: ImageCompression
    private let onResult: (Result<[File], any Error>) -> Void
    private let onCancel: () -> Void
    private let onStartAssetsProcessing: () -> Void
    private let onEndAssetsProcessing: () -> Void
    
    init(
        source: Source,
        onResult: @escaping (Result<[File], any Error>) -> Void,
        onCancel: @escaping () -> Void,
        onStartAssetsProcessing: @escaping () -> Void,
        onEndAssetsProcessing: @escaping () -> Void
    ) {
        switch source {
        case let .photos(selectionLimit, cropMode, compression):
            if selectionLimit > 1 && cropMode != .notAllowed {
                assertionFailure("Crop mode is not allowed when the selection limit is more than one")
            }
            
            self.cropMode = cropMode
            self.compression = compression
            
        case .multimedia(_, let imageCompression), .videos(_, let imageCompression):
            self.cropMode = .notAllowed
            self.compression = imageCompression
            
        case .camera(let cropMode, let compression):
            self.cropMode = cropMode
            self.compression = compression
        }
        
        self.source = source
        self.onResult = onResult
        self.onCancel = onCancel
        self.onStartAssetsProcessing = onStartAssetsProcessing
        self.onEndAssetsProcessing = onEndAssetsProcessing
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MediaPickerView>) -> UIViewController {
        switch source {
        case .photos(let selectionLimit, _, _):
            assert(!(selectionLimit > 1 && cropMode.isCropAllowed), "Crop mode is set to allowed while selection limit is more than one, this is not allowed!")
            
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.images])
            configuration.selectionLimit = selectionLimit
            
            let photosPickerViewController = PHPickerViewController(configuration: configuration)
            photosPickerViewController.delegate = context.coordinator
            
            context.coordinator.viewController = photosPickerViewController
            
            return photosPickerViewController
            
        case .videos(let selectionLimit, _):
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.videos])
            configuration.selectionLimit = selectionLimit
            
            let photosPickerViewController = PHPickerViewController(configuration: configuration)
            photosPickerViewController.delegate = context.coordinator
            
            context.coordinator.viewController = photosPickerViewController
            
            return photosPickerViewController
            
        case .multimedia(let selectionLimit, _):
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.images, .videos])
            configuration.selectionLimit = selectionLimit
            
            let photosPickerViewController = PHPickerViewController(configuration: configuration)
            photosPickerViewController.delegate = context.coordinator
            
            context.coordinator.viewController = photosPickerViewController
            
            return photosPickerViewController
            
        case .camera:
            let viewController = UIViewController()
            
            makeImagePickerController(
                delegate: context.coordinator,
                addedTo: viewController
            )
            
            context.coordinator.viewController = viewController
            
            return viewController
        }
    }
    
    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: UIViewControllerRepresentableContext<MediaPickerView>
    ) { }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    private func makeImagePickerController(
        delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate,
        addedTo parent: UIViewController
    ) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = delegate
        
        parent.children.forEach { $0.removeFromParent() }
        parent.view.subviews.forEach { $0.removeFromSuperview() }
        
        parent.view.addSubview(imagePickerController.view)
        parent.addChild(imagePickerController)
        
        imagePickerController.view.frame = parent.view.bounds
    }
}

extension MediaPickerView {
    class Coordinator: NSObject {
        private let parent: MediaPickerView
        weak var viewController: UIViewController?
        
        init(_ parent: MediaPickerView) {
            self.parent = parent
        }
        
        func makeCropViewController(with image: UIImage, presetFixedRatioType: PresetFixedRatioType) -> CropViewController {
            var config = Mantis.Config()
            config.presetFixedRatioType = presetFixedRatioType
            
            let cropViewController = Mantis.cropViewController(
                image: image,
                config: config
            )
            
            cropViewController.delegate = self
            return cropViewController
        }
        
        private func process(image: UIImage) throws -> File {
            switch parent.compression {
            case .compressed(let maximumSize, let quality):
                let resizedImage = image.resized(to: maximumSize)
                
                guard
                    let data = resizedImage.jpegData(compressionQuality: quality.value)
                else {
                    assertionFailure("The image has no data or the underlying CGImageRef contains data in an unsupported bitmap format.")
                    throw MediaPickerError.corruptedImage
                }
                
                let imageFile = ImageFile(
                    id: UUID().uuidString,
                    image: resizedImage,
                    metadata: FileMetadata(
                        data: data,
                        size: resizedImage.size,
                        uniformType: .jpeg
                    )
                )
                
                return File(type: .image(imageFile))
                
            case .original:
                guard
                    let data = image.jpegData(compressionQuality: 1.0)
                else {
                    assertionFailure("The image has no data or the underlying CGImageRef contains data in an unsupported bitmap format.")
                    throw MediaPickerError.corruptedImage
                }
                
                let imageFile = ImageFile(
                    id: UUID().uuidString,
                    image: image,
                    metadata: FileMetadata(
                        data: data,
                        size: image.size,
                        uniformType: .jpeg
                    )
                )
                
                return File(type: .image(imageFile))
            }
        }
        
        private func process(video url: URL) async throws -> File {
            let asset = AVURLAsset(url: URL(fileURLWithPath: url.path))
            let previewImage = try await asset.previewImage()
            let videoResolution = await asset.resolution()
            
            if videoResolution == nil {
                print("[FilesPicker] ⚠️ Unable to calculate size for video, will default to image size")
            }
            
            switch parent.compression {
            case .compressed(let maximumSize, let quality):
                do {
                    let resizedPreviewImage = previewImage.resized(to: maximumSize)
                    guard 
                        let previewImageData = resizedPreviewImage.jpegData(compressionQuality: quality.value)
                    else {
                        throw MediaPickerError.corruptedVideoPreviewImage
                    }
                    
                    let previewImageFile = ImageFile(
                        id: UUID().uuidString,
                        image: resizedPreviewImage,
                        metadata: FileMetadata(
                            data: previewImageData,
                            size: resizedPreviewImage.size,
                            uniformType: .jpeg
                        )
                    )
                    
                    let videoFile = VideoFile(
                        id: UUID().uuidString,
                        url: url,
                        metadata: FileMetadata(
                            data: try Data(contentsOf: url),
                            size: videoResolution ?? resizedPreviewImage.size,
                            uniformType: UTType(filenameExtension: url.pathExtension)
                        ),
                        previewImage: previewImageFile
                    )
                    
                    return File(type: .video(videoFile))
                } catch {
                    throw error
                }
                
            case .original:
                do {
                    guard 
                        let previewImageData = previewImage.jpegData(compressionQuality: 1.0)
                    else {
                        throw MediaPickerError.corruptedVideoPreviewImage
                    }
                    
                    let previewImageFile = ImageFile(
                        id: UUID().uuidString,
                        image: previewImage,
                        metadata: FileMetadata(
                            data: previewImageData,
                            size: previewImage.size,
                            uniformType: .jpeg
                        )
                    )
                    
                    let videoFile = VideoFile(
                        id: UUID().uuidString,
                        url: url,
                        metadata: FileMetadata(
                            data: try Data(contentsOf: url),
                            size: videoResolution ?? previewImage.size,
                            uniformType: UTType(filenameExtension: url.pathExtension)
                        ),
                        previewImage: previewImageFile
                    )
                    
                    return File(type: .video(videoFile))
                } catch {
                    throw error
                }
            }
        }
        

    }
}

extension MediaPickerView.Coordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        var image = UIImage()
        
        if let editedImage = info[.editedImage] as? UIImage {
            image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            image = originalImage
        }
        
        switch parent.cropMode {
        case .allowed(let presetFixedRatioType):
            viewController?.present(
                makeCropViewController(with: image, presetFixedRatioType: presetFixedRatioType),
                animated: true
            )
            
        case .notAllowed:
            parent.presentationMode.wrappedValue.dismiss()
            
            do {
                let file = try process(image: image)
                parent.onResult(.success([file]))
            } catch {
                parent.onResult(.failure(error))
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.presentationMode.wrappedValue.dismiss()
        parent.onCancel()
    }
}

extension MediaPickerView.Coordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.isEmpty {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCancel()
        } else {
            Task { @MainActor in
                if parent.cropMode == .notAllowed {
                    parent.presentationMode.wrappedValue.dismiss()
                }
                
                parent.onStartAssetsProcessing()
                
                do {
                    let itemProviders = results.map(\.itemProvider)
                    let files = try await makeFiles(from: itemProviders)
                    parent.onEndAssetsProcessing()
                    process(files: files)
                } catch {
                    parent.onResult(.failure(error))
                }
            }
        }
    }
    
    private func makeFiles(from itemProviders: [NSItemProvider]) async throws -> [File] {
        return try await withThrowingTaskGroup(of: (index: Int, file: File).self) { group in
            var filesWithIndices: [(index: Int, file: File)] = []
            
            for (index, itemProvider) in itemProviders.enumerated() {
                group.addTask {
                    let file: File
                    
                    if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                        let url = try await itemProvider.loadURL(for: .movie)
                        file = try await self.process(video: url)
                    } else {
                        let url = try await itemProvider.loadURL(for: .image)
                        let data = try await self.loadImageData(from: url)
                        
                        guard
                            let image = UIImage(data: data)
                        else {
                            throw MediaPickerError.corruptedImage
                        }
                        
                        file = try self.process(image: image)
                    }
                    
                    return (index, file)
                }
            }
            
            for try await (index, file) in group {
                filesWithIndices.append((index, file))
            }
            
            let sortedFiles = filesWithIndices.sorted(by: { $0.index < $1.index })
            let files = sortedFiles.map(\.file)
            return files
        }
    }
    
    private func loadImageData(from url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            
            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2_000,
            ] as [CFString : Any] as CFDictionary
            
            let destinationProperties = [
                kCGImageDestinationLossyCompressionQuality: 1
            ] as CFDictionary
            
            let data = NSMutableData()
            
            guard
                let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions),
                let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions),
                let imageDestination = CGImageDestinationCreateWithData(data, cgImage.utType ?? UTType.jpeg.identifier as CFString, 1, nil)
            else {
                continuation.resume(throwing: MediaPickerError.unableToCreateImage)
                return
            }
            
            CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
            CGImageDestinationFinalize(imageDestination)
            
            continuation.resume(returning: data as Data)
        }
    }
    
    private func process(files: [File]) {
        switch parent.cropMode {
        case .allowed(let presetFixedRatioType):
            let images = files.compactMap { file in
                if case .image(let fileType) = file.type {
                    return fileType.image
                } else {
                    return nil
                }
            }
            
            let videos = files.filter { file in
                if case .video = file.type {
                    return true
                } else {
                    return false
                }
            }
            
            if images.count == 1 && videos.isEmpty {
                let image = images[0]
                
                viewController?.present(
                    makeCropViewController(with: image, presetFixedRatioType: presetFixedRatioType),
                    animated: true
                )
            } else {
                assertionFailure("Crop mode is set to allowed while there is video or more than one image, this is not allowed!")
                parent.presentationMode.wrappedValue.dismiss()
                parent.onResult(.success(files))
            }
            
        case .notAllowed:
            parent.presentationMode.wrappedValue.dismiss()
            parent.onResult(.success(files))
        }
    }
}

extension MediaPickerView.Coordinator: CropViewControllerDelegate {
    func cropViewControllerDidCrop(
        _ cropViewController: CropViewController,
        cropped: UIImage,
        transformation: Transformation,
        cropInfo: CropInfo
    ) {
        do {
            let file = try process(image: cropped)
            parent.onResult(.success([file]))
        } catch {
            parent.onResult(.failure(error))
        }
        
        cropViewController.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true) { [weak self] in
            guard
                let self,
                let viewController = viewController
            else {
                return
            }
            
            // If the sourceType is camera, we need to recreate the ViewController
            switch parent.source {
            case .photos, .videos, .multimedia:
                // No-op
                break
                
            case .camera:
                parent.makeImagePickerController(
                    delegate: self,
                    addedTo: viewController
                )
            }
        }
    }
    
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
        
    }
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
        
    }
    
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
        
    }
}

extension NSItemProvider: @unchecked Sendable {
    
}

private extension NSItemProvider {
    public enum NSItemProviederError: Error {
        case unknownError
    }
    
    func loadURL(for type: UTType) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                let result = Result(value: url, error: error)
                
                do {
                    let url = try result.get()
                    let temporaryURL = try url.moveToTempDirectory(fileName: UUID().uuidString)
                    continuation.resume(returning: temporaryURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private extension Result where Failure == Error {
    private struct UnknownError: Error { }
    
    init(value: Success?, error: Failure?) {
        if let value = value {
            self = .success(value)
        } else if let error = error {
            self = .failure(error)
        } else {
            self = .failure(UnknownError())
        }
    }
}
