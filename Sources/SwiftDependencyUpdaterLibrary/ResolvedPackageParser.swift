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
        if let version {
            return "\(version)"
        }
        return "\(revision)"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        branch = try? container.decode(String?.self, forKey: .branch)
        revision = try container.decode(String.self, forKey: .revision)
        if let versionString = try container.decode(String?.self, forKey: .version) {
            version = try Version(string: versionString)
        } else {
            version = nil
        }
    }
}

protocol ResolvedDependency: Decodable {
    var name: String { get }
    var url: URL { get }
    var version: ResolvedVersion { get }
}

struct ResolvedDependencyV1: ResolvedDependency {
    enum CodingKeys: String, CodingKey {
        case name = "package"
        case url = "repositoryURL"
        case version = "state"
    }

    let name: String
    let url: URL
    let version: ResolvedVersion
}

struct ResolvedDependencyV2: ResolvedDependency {
    enum CodingKeys: String, CodingKey {
        case name = "identity"
        case url = "location"
        case version = "state"
    }

    let name: String
    let url: URL
    let version: ResolvedVersion
}

private struct WrapperV1: Decodable {
    let object: ResolvedPackageV1
}
struct ResolvedPackageV1: ResolvedPackage {
    typealias Dependency = ResolvedDependencyV1

    enum CodingKeys: String, CodingKey {
        case dependencies = "pins"
    }

    let dependencies: [ResolvedDependencyV1]
}

enum ResolvedPackageError: Error, Equatable {
    case resolvingFailed(String)
    case readingFailed(String)
    case parsingFailed(String, String)
}

protocol ResolvedPackage: Decodable {
    associatedtype Dependency: ResolvedDependency

    var dependencies: [Dependency] { get }
}

struct ResolvedPackageV2: ResolvedPackage {
    typealias Dependency = ResolvedDependencyV2

    enum CodingKeys: String, CodingKey {
        case dependencies = "pins"
    }

    let dependencies: [ResolvedDependencyV2]
}

enum ResolvedPackageParser {
    static func resolveAndLoadResolvedPackage(from folder: URL) throws -> any ResolvedPackage {
         do {
            try shellOut(to: "swift", arguments: ["package", "--package-path", "\"\(folder.path)\"", "resolve" ])
        } catch {
            let error = error as! ShellOutError // swiftlint:disable:this force_cast
            throw ResolvedPackageError.resolvingFailed(error.message)
        }
        return try loadResolvedPackage(from: folder)
    }

    static func loadResolvedPackage(from folder: URL) throws -> any ResolvedPackage {
        let data = try readResolvedPackageData(from: folder)
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(WrapperV1.self, from: data).object
        } catch {
            do {
                return try decoder.decode(ResolvedPackageV2.self, from: data)
            } catch {
                throw ResolvedPackageError.parsingFailed(error.localizedDescription, String(bytes: data, encoding: .utf8) ?? "")
            }
        }
    }

    private static func readResolvedPackageData(from folder: URL) throws -> Data {
        let resolvedPackage = folder.appendingPathComponent("Package.resolved", isDirectory: false)
        do {
            return try Data(contentsOf: resolvedPackage)
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
        if let version {
            return "\(version) (\(revision)\(branch != nil ? ", branch: \(branch!)" : ""))"
        }
        return "\(revision)\(branch != nil ? " (branch: \(branch!))" : "")"
    }
}
