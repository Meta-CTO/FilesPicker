import UIKit
import AVKit

extension URL {
    func moveToTempDirectory(fileName: String) throws -> URL {
        let pathName = fileName + "." + pathExtension
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let targetURL = temporaryDirectoryURL.appendingPathComponent(pathName)
        try FileManager.default.copyItem(at: self, to: targetURL)
        return targetURL
    }
}
