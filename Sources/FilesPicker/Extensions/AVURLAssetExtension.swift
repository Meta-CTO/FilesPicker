import AVKit

public extension AVURLAsset {
    func previewImage() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let assetImageGenerator = AVAssetImageGenerator(asset: self)
            assetImageGenerator.appliesPreferredTrackTransform = true
            assetImageGenerator.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
            
            let cmTime = CMTime(seconds: 0, preferredTimescale: 60)
            assetImageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { _, image, _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard
                    let image
                else {
                    continuation.resume(throwing: MediaPickerError.corruptedVideoPreviewImage)
                    return
                }
                
                continuation.resume(returning: UIImage(cgImage: image))
            }
        }
    }
    
    func resolution() async -> CGSize? {
        return await withCheckedContinuation { continuation in
            loadValuesAsynchronously(forKeys: ["tracks"]) { [weak self] in
                guard
                    let self,
                    let track = tracks(withMediaType: .video).first
                else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let naturalSize = track.naturalSize.applying(track.preferredTransform)
                let size = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
                continuation.resume(returning: size)
            }
        }
    }
}
