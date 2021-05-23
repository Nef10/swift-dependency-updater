import Foundation
import ShellOut

enum SwiftPackageError: Error, Equatable {
    case invalidUpdate(String, Update)
    case resultCountMismatch(String, Int)
    case noResultMatch(String, [String?])
    case readFailed(String)
    case writeFailed(String)
}

struct SwiftPackage {

    private let folder: URL
    private let url: URL

    init(in folder: URL) {
        self.folder = folder
        url = folder.appendingPathComponent("Package.swift", isDirectory: false)
    }

    func performUpdate(_ update: Update, of dependency: Dependency) throws -> Bool {
        guard case var .withChangingRequirements(updatedVersion) = update else {
            throw SwiftPackageError.invalidUpdate(dependency.name, update)
        }

        var string = try read()
        let nsString = string as NSString

        // swiftlint:disable:next line_length
        let versionRegExString = "(\\.upToNextMajor\\s*\\(\\s*from\\s*:\\s*\"([0-9]*\\.[0-9]*\\.[0-9]*)\"\\s*\\))|(\\.upToNextMinor\\s*\\(\\s*from\\s*:\\s*\"([0-9]*\\.[0-9]*\\.[0-9]*)\"\\s*\\))|(\\.exact\\s*\\(\\s*\"([0-9]*\\.[0-9]*\\.[0-9]*)\"\\s*\\))|(from\\s*:\\s*\\s*\"([0-9]*\\.[0-9]*\\.[0-9]*)\")|(\\s*\"[0-9]*\\.[0-9]*\\.[0-9]*\"\\.\\.\\.\"([0-9]*\\.[0-9]*\\.[0-9]*)\")|(\\s*\"[0-9]*\\.[0-9]*\\.[0-9]*\"\\.\\.<\"([0-9]*\\.[0-9]*\\.[0-9]*)\")"
        // swiftlint:disable:next line_length
        let regex = try NSRegularExpression(pattern: "dependencies\\s*:\\s*\\[\\s*[^\\]]*\\.package\\s*\\(\\s*url\\s*:\\s*\"\(NSRegularExpression.escapedPattern(for: dependency.url.absoluteString))\"\\s*,\\s*(\(versionRegExString))", options: [.anchorsMatchLines])

        let results = string.matchingStringsWithRange(regex: regex)
        guard results.count == 1, let matches = results[safe: 0] else {
            throw SwiftPackageError.resultCountMismatch(dependency.name, results.count)
        }

        var packageUpdate = false
        if matches[2] != nil, let version = matches[3] {
            string = nsString.replacingCharacters(in: version.range, with: "\(updatedVersion)")
        } else if matches[4] != nil, let version = matches[5] {
            string = nsString.replacingCharacters(in: version.range, with: "\(updatedVersion)")
        } else if matches[6] != nil, let version = matches[7] {
            string = nsString.replacingCharacters(in: version.range, with: "\(updatedVersion)")
        } else if matches[8] != nil, let version = matches[9] {
            string = nsString.replacingCharacters(in: version.range, with: "\(updatedVersion)")
        } else if matches[10] != nil, let version = matches[11] {
            string = nsString.replacingCharacters(in: version.range, with: "\(updatedVersion)")
            packageUpdate = true
        } else if matches[12] != nil, let version = matches[13] {
            updatedVersion.patch += 1
            string = nsString.replacingCharacters(in: version.range, with: "\(updatedVersion)")
            packageUpdate = true
        } else {
            throw SwiftPackageError.noResultMatch(dependency.name, matches.map { $0?.string })
        }

        try write(string)
        return packageUpdate
    }

    private func read() throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw SwiftPackageError.readFailed(error.localizedDescription)
        }
    }

    private func write(_ string: String) throws {
        do {
            try string.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw SwiftPackageError.writeFailed(error.localizedDescription)
        }
    }

}

extension SwiftPackageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidUpdate(name, update):
            return "Invalid update for \(name): \(update)"
        case let .resultCountMismatch(name, count):
            return "Finding version requirement in Package.swift failed for \(name): Got \(count) instead of 1 result"
        case let .noResultMatch(name, results):
            return "Finding version requirement in Package.swift failed for \(name). Findings: \(results)"
        case let .readFailed(error):
            return "Failed to read Package.swift file: \(error)"
        case let .writeFailed(error):
            return "Failed to write Package.swift file: \(error)"
        }
    }
}
