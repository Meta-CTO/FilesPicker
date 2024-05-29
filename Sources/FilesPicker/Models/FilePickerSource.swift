public enum FilePickerSource: Identifiable {
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
    
    /// Allows picking files from documents
    case files(allowMultipleSelection: Bool)
    
    public var id: String {
        switch self {
        case .camera:
            return "camera"
            
        case .photos:
            return "photos"
            
        case .videos:
            return "videos"
            
        case .multimedia:
            return "multimedia"
            
        case .files:
            return "files"
        }
    }
}
