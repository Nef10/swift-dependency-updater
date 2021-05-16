import Foundation
import Releases
import ShellOut

struct PackageDependency: Decodable {
    let name: String
    let requirement: DependencyRequirement
    let url: URL
}

enum DependencyRequirement: Decodable {

    case exact(version: Version)
    case revision(revision: String)
    case branch(name: String)
    case range(lowerBound: Version, upperBound: Version)

    enum CodingKeys: String, CodingKey {
        case exact
        case revision
        case branch
        case range
    }

    enum RangeCodingKeys: String, CodingKey {
        case lowerBound
        case upperBound
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        switch key {
        case .exact:
            var nestedUnkeyedContainer = try container.nestedUnkeyedContainer(forKey: .exact)
            let versionString = try nestedUnkeyedContainer.decode(String.self)
            let version = try Version(string: versionString)
            self = .exact(version: version)
        case .revision:
            var nestedUnkeyedContainer = try container.nestedUnkeyedContainer(forKey: .revision)
            let revision = try nestedUnkeyedContainer.decode(String.self)
            self = .revision(revision: revision)
        case .branch:
            var nestedUnkeyedContainer = try container.nestedUnkeyedContainer(forKey: .branch)
            let name = try nestedUnkeyedContainer.decode(String.self)
            self = .branch(name: name)
        case .range:
            var nestedUnkeyedContainer = try container.nestedUnkeyedContainer(forKey: .range)
            let nestedContainer = try nestedUnkeyedContainer.nestedContainer(keyedBy: RangeCodingKeys.self)
            let lowerBoundString = try nestedContainer.decode(String.self, forKey: RangeCodingKeys.lowerBound)
            let upperBoundString = try nestedContainer.decode(String.self, forKey: RangeCodingKeys.upperBound)
            let lowerBound = try Version(string: lowerBoundString)
            let upperBound = try Version(string: upperBoundString)
            self = .range(lowerBound: lowerBound, upperBound: upperBound)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode enum"
                )
            )
        }
    }
}

enum PackageDescriptionError: Error {
    case loadingFailed(String)
    case parsingFailed(String, String)
}

struct PackageDescription: Decodable {
    let dependencies: [PackageDependency]

    static func loadPackageDescription(from folder: URL) throws -> Self {
        let json = try readPackageDescription(from: folder)
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        do {
            let packageDescription = try decoder.decode(Self.self, from: data)
            return packageDescription
        } catch {
            throw PackageDescriptionError.parsingFailed(error.localizedDescription, json)
        }
    }

    private static func readPackageDescription(from folder: URL) throws -> String {
        do {
            let output = try shellOut(to: "swift", arguments: ["package", "dump-package", "--package-path", "\"\(folder.path)\"" ])
            return output
        } catch {
            let error = error as! ShellOutError // swiftlint:disable:this force_cast
            throw PackageDescriptionError.loadingFailed(error.message)
        }
    }
}

extension PackageDescriptionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .loadingFailed(error):
            return "Could not get package data, swift package dump-package failed: \(error)"
        case let .parsingFailed(error, packageData):
            return "Could not parse package data: \(error)\n\nPackage Data: \(packageData)"
        }
    }
}

extension DependencyRequirement: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .exact(version):
            return "\(version)"
        case let .revision(revision):
            return revision
        case let .branch(name):
            return name
        case let .range(lowerBound, upperBound):
            return "\(lowerBound)..<\(upperBound)"
        }
    }
}
