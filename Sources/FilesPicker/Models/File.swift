import UIKit
import UniformTypeIdentifiers

public struct FileMetadata: Sendable, Hashable {
    public let data: Data
    public let size: CGSize?
    public let uniformType: UTType?
    
    public init(
        data: Data,
        size: CGSize?,
        uniformType: UTType?
    ) {
        self.data = data
        self.size = size
        self.uniformType = uniformType
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(size?.width)
        hasher.combine(size?.height)
        hasher.combine(uniformType)
    }
}

public struct ImageFile: Sendable, Hashable {
    public let id: String
    public let image: UIImage
    public let metadata: FileMetadata
    
    public init(
        id: String,
        image: UIImage,
        metadata: FileMetadata
    ) {
        self.id = id
        self.image = image
        self.metadata = metadata
    }
}

public struct VideoFile: Sendable, Hashable {
    public let id: String
    public let url: URL
    public let metadata: FileMetadata
    public let previewImage: ImageFile
    
    public init(
        id: String,
        url: URL,
        metadata: FileMetadata,
        previewImage: ImageFile
    ) {
        self.id = id
        self.url = url
        self.metadata = metadata
        self.previewImage = previewImage
    }
}

public struct OtherFile: Sendable, Hashable {
    public let id: String
    public let url: URL
    public let metadata: FileMetadata
    
    public init(
        id: String,
        url: URL,
        metadata: FileMetadata
    ) {
        self.id = id
        self.url = url
        self.metadata = metadata
    }
}

public enum FileType: Sendable, Hashable {
    case image(ImageFile)
    case video(VideoFile)
    case file(OtherFile)
    
    var id: String {
        switch self {
        case .image(let file):
            file.id
            
        case .video(let file):
            file.id
            
        case .file(let file):
            file.id
        }
    }
    
    var data: Data {
        switch self {
        case .image(let file):
            file.metadata.data
            
        case .video(let file):
            file.metadata.data
            
        case .file(let file):
            file.metadata.data
        }
    }
    
    var width: Int? {
        switch self {
        case .image(let file):
            file.metadata.size.map { Int($0.width) }
            
        case .video(let file):
            file.metadata.size.map { Int($0.width) }
            
        case .file(let file):
            file.metadata.size.map { Int($0.width) }
        }
    }
    
    var height: Int? {
        switch self {
        case .image(let file):
            file.metadata.size.map { Int($0.height) }
            
        case .video(let file):
            file.metadata.size.map { Int($0.height) }
            
        case .file(let file):
            file.metadata.size.map { Int($0.height) }
        }
    }
    
    var uniformType: UTType? {
        switch self {
        case .image(let file):
            file.metadata.uniformType
            
        case .video(let file):
            file.metadata.uniformType
            
        case .file(let file):
            file.metadata.uniformType
        }
    }
}

public struct File: Identifiable, Sendable, Hashable {
    public let name: String
    public let type: FileType
    
    public init(type: FileType) {
        self.name = switch type {
        case .image(let file):
            "\(UUID().uuidString).\(file.metadata.uniformType?.preferredFilenameExtension ?? "")"
        case .video(let file):
            "\(UUID().uuidString).\(file.metadata.uniformType?.preferredFilenameExtension ?? "")"
        case .file(let file):
            "\(UUID().uuidString).\(file.metadata.uniformType?.preferredFilenameExtension ?? "")"
        }
        
        self.type = type
    }
    
    public func getSizeIn(_ type: Data.DataUnit) -> Double {
        let data = switch self.type {
        case .image(let file):
            file.metadata.data
            
        case .video(let file):
            file.metadata.data
            
        case .file(let file):
            file.metadata.data
        }
        
        let size = type.convert(from: Double(data.count))
        return size
    }
}

public extension File {
    var id: String { type.id }
    
    var data: Data { type.data }
    
    var width: Int? { type.width }
    
    var height: Int? { type.height }
    
    var uniformType: UTType? { type.uniformType }
}
