import Foundation
import Releases
import ShellOut

struct ResolvedVersion: Decodable {

    enum CodingKeys: String, CodingKey {
        case branch
        case revision
        case version
    }

    let branch: String?
    let revision: String
    let version: Version?

    public var versionNumberOrRevision: String {
        if let version = version {
            return "\(version)"
        } else {
            return "\(revision)"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        branch = try container.decode(String?.self, forKey: .branch)
        revision = try container.decode(String.self, forKey: .revision)
        if let versionString = try container.decode(String?.self, forKey: .version) {
            version = try Version(string: versionString)
        } else {
            version = nil
        }
    }
}

struct ResolvedDependency: Decodable {
    enum CodingKeys: String, CodingKey {
        case name = "package"
        case url = "repositoryURL"
        case version = "state"
    }

    let name: String
    let url: URL
    let version: ResolvedVersion
}

private struct Wrapper: Decodable {
    let object: ResolvedPackage
}

enum ResolvedPackageError: Error, Equatable {
    case resolvingFailed(String)
    case readingFailed(String)
    case parsingFailed(String, String)
}

struct ResolvedPackage: Decodable {
    enum CodingKeys: String, CodingKey {
        case dependencies = "pins"
    }

    let dependencies: [ResolvedDependency]

    static func resolveAndLoadResolvedPackage(from folder: URL) throws -> ResolvedPackage {
         do {
            try shellOut(to: "swift", arguments: ["package", "resolve", "--package-path", "\"\(folder.path)\"" ])
        } catch {
            let error = error as! ShellOutError // swiftlint:disable:this force_cast
            throw ResolvedPackageError.resolvingFailed(error.message)
        }
        return try loadResolvedPackage(from: folder)
    }

    static func loadResolvedPackage(from folder: URL) throws -> ResolvedPackage {
        let data = try readResolvedPackageData(from: folder)
        let decoder = JSONDecoder()
        do {
            let resolvedPackage = try decoder.decode(Wrapper.self, from: data).object
            return resolvedPackage
        } catch {
            throw ResolvedPackageError.parsingFailed(error.localizedDescription, String(decoding: data, as: UTF8.self))
        }
    }

    private static func readResolvedPackageData(from folder: URL) throws -> Data {
        let resolvedPackage = folder.appendingPathComponent("Package.resolved", isDirectory: false)
        do {
            let contents = try Data(contentsOf: resolvedPackage)
            return contents
        } catch {
            throw ResolvedPackageError.readingFailed(error.localizedDescription)
        }
    }
}

extension ResolvedPackageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .resolvingFailed(error):
            return "Running swift package resolved failed: \(error)"
        case let .readingFailed(error):
            return "Could not read Package.resolved file: \(error)"
        case let .parsingFailed(error, packageData):
            return "Could not parse package data: \(error)\n\nPackage Data: \(packageData)"
        }
    }
}

extension ResolvedVersion: CustomStringConvertible {
    public var description: String {
        if let version = version {
            return "\(version) (\(revision)\(branch != nil ? ", branch: \(branch!)" : ""))"
        } else {
            return "\(revision)\(branch != nil ? " (branch: \(branch!))" : "")"
        }
    }
}
