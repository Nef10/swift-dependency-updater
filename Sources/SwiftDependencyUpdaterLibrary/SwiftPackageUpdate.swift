import Foundation
import Releases
import ShellOut

enum SwiftPackageUpdateError: Error, Equatable {
    case loadingFailed(String)
    case parsingNumberFailed(String)
    case parsingNumberMismatch(String, Int, Int)
    case parsingDependencyFailed(String, [String])
}

struct SwiftPackageUpdate {

    private static let numberRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "^([0-9]+) dependenc(y|ies) ha(s|ve) changed(.|:)$", options: [.anchorsMatchLines])
    }()

    private static let dependencyRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "^~ ([^\\s]*) ([^\\s]*) -> ([^\\s]*) ([^\\s]*)$", options: [.anchorsMatchLines])
    }()

    let name: String
    let oldVersion: Version
    let newVersion: Version

    static func checkUpdates(in folder: URL) throws -> [SwiftPackageUpdate] {
        let string = try readUpdates(in: folder)
        return try parseOutput(string)
    }

    private static func readUpdates(in folder: URL) throws -> String {
         do {
            return try shellOut(to: "swift", arguments: ["package", "--package-path", "\"\(folder.path)\"", "update", "--dry-run" ])
        } catch {
            let error = error as! ShellOutError // swiftlint:disable:this force_cast
            throw SwiftPackageUpdateError.loadingFailed(error.message)
        }
    }

    private static func parseOutput(_ output: String) throws -> [SwiftPackageUpdate] {
        let numberMatches = output.matchingStrings(regex: self.numberRegex)
        guard
            let match = numberMatches[safe: 0],
            let numberString = match[safe: 1],
            let number = Int(numberString)
        else {
            throw SwiftPackageUpdateError.parsingNumberFailed(output)
        }
        let dependencyMatches = output.matchingStrings(regex: self.dependencyRegex)
        guard dependencyMatches.count == number else {
            throw SwiftPackageUpdateError.parsingNumberMismatch(output, number, dependencyMatches.count)
        }
        var result = [SwiftPackageUpdate]()
        for dependencyMatch in dependencyMatches {
            guard
                let name = dependencyMatch[safe: 1],
                let oldVersionString = dependencyMatch[safe: 2],
                let oldVersion = try? Version(string: oldVersionString),
                let name2 = dependencyMatch[safe: 3],
                let newVersionString = dependencyMatch[safe: 4],
                let newVersion = try? Version(string: newVersionString),
                name == name2
            else {
                throw SwiftPackageUpdateError.parsingDependencyFailed(output, dependencyMatch)
            }
            result.append(Self(name: name, oldVersion: oldVersion, newVersion: newVersion))
        }
        return result
    }

}

extension SwiftPackageUpdate: CustomStringConvertible {
    public var description: String {
        "\("\(oldVersion) -> \(newVersion)".yellow) (Without changing requirements)"
    }
}

extension SwiftPackageUpdateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .loadingFailed(error):
            return "Could not get package update data, swift package update failed: \(error)"
        case let .parsingNumberFailed(output):
            return "Could not parse number of package updates from the swift package update output: \(output)"
        case let .parsingNumberMismatch(output, number, parsed):
            return "The number of package updates (\(number)) from the swift package update output mismatches the number of updates parsed (\(parsed)). Output: \(output)"
        case let .parsingDependencyFailed(output, match):
            return "Could not parse a dependency (\(match)) from the swift package update output: \(output)"
        }
    }
}
