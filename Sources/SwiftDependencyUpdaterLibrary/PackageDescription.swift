import Foundation
import Releases
import ShellOut

protocol PackageDependency: Decodable {

    var name: String { get }
    var requirement: DependencyRequirement { get }
    var url: URL { get }

}

private struct PackageDependencyV54: PackageDependency {

    let name: String
    let requirement: DependencyRequirement
    let url: URL
}

private struct PackageDependencyV55: PackageDependency {

    enum CodingKeys: String, CodingKey {
        case name = "identity"
        case requirement
        case url = "location"
    }

    let name: String
    let requirement: DependencyRequirement
    let url: URL
}

private struct PackageDependencyV56: PackageDependency {

    enum CodingKeys: String, CodingKey {
        case name = "identity"
        case requirement
        case location
    }

    let name: String
    let requirement: DependencyRequirement
    let location: PackageLocation

    var url: URL {
        location.remote.first!
    }
}

private struct PackageLocation: Decodable {
    let remote: [URL]
}

enum DependencyRequirement: Decodable, Equatable {

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
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unabled to decode enum")
            )
        }
    }
}

enum PackageDescriptionError: Error, Equatable {
    case loadingFailed(String)
    case parsingFailed(String, String)
}

struct PackageDescriptionV54: PackageDescription {

    enum CodingKeys: String, CodingKey {
        case dependenciesArray = "dependencies"
    }

    private let dependenciesArray: [PackageDependencyV54]
    var dependencies: [PackageDependency] {
        dependenciesArray
    }

}

struct PackageDescriptionV55: PackageDescription {

    enum CodingKeys: String, CodingKey {
        case dependencyMap = "dependencies"
    }

    private let dependencyMap: [[String: [PackageDependencyV55]]]
    var dependencies: [PackageDependency] {
        dependencyMap.flatMap { $0.values.flatMap { $0 } }
    }

}

struct PackageDescriptionV56: PackageDescription {

    enum CodingKeys: String, CodingKey {
        case dependencyMap = "dependencies"
    }

    private let dependencyMap: [[String: [PackageDependencyV56]]]
    var dependencies: [PackageDependency] {
        dependencyMap.flatMap { $0.values.flatMap { $0 } }
    }

}

enum PackageDescriptionFactory {
    static func loadPackageDescription(from folder: URL) throws -> PackageDescription {
        let json = try readPackageDescription(from: folder)
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(PackageDescriptionV56.self, from: data)
        } catch {
            do {
                return try decoder.decode(PackageDescriptionV55.self, from: data)
            } catch {
                do {
                    return try decoder.decode(PackageDescriptionV54.self, from: data)
                } catch {
                    throw PackageDescriptionError.parsingFailed(String(describing: error), json)
                }
            }
        }
    }

    private static func readPackageDescription(from folder: URL) throws -> String {
        do {
            return try shellOut(to: "swift", arguments: ["package", "--package-path", "\"\(folder.path)\"", "dump-package" ])
        } catch {
            let error = error as! ShellOutError // swiftlint:disable:this force_cast
            throw PackageDescriptionError.loadingFailed(error.message)
        }
    }
}

protocol PackageDescription: Decodable {
    var dependencies: [PackageDependency] { get }
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
