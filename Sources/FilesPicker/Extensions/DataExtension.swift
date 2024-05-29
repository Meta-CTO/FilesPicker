import Foundation

extension Data {
    public enum DataUnit: String {
        case byte, kilobyte, megabyte
        case gigabyte
        
        func convert(from size: Double) -> Double {
            switch self {
            case .byte:
                return size
                
            case .kilobyte:
                return size / 1024
                
            case .megabyte:
                return size / 1024 / 1024
                
            case .gigabyte:
                return size / 1024 / 1024 / 1024
            }
        }
    }
    
    public func getSizeIn(_ type: DataUnit) -> Double {
        let size = type.convert(from: Double(count))
        return size
    }
    
    func writeToTempDirectory(fileName: String) throws -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let targetURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        try write(to: targetURL)
        return targetURL
    }
}
