import Foundation
import Rainbow
import Releases

enum DependencyError: Error {
    case loadingFailed(String)
    case parsingFailed(String, String)
}

struct Dependency {
    let name: String
    let url: URL
    let requirement: DependencyRequirement?
    let resolvedVersion: ResolvedVersion
    let update: Update?

    var branchNameForUpdate: String {
        "swift-dependency-updater/\(name.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-").lowercased())"
    }

    static func loadDependencies(from folder: URL) throws -> [Dependency] {
        let packageDescription = try PackageDescription.loadPackageDescription(from: folder)
        let resolvedPackage = try ResolvedPackage.loadResolvedPackage(from: folder)
        let swiftPackageUpdates = try SwiftPackageUpdate.checkUpdates(in: folder)
        return try mergeDependencies(packageDescription: packageDescription, resolvedPackage: resolvedPackage, swiftPackageUpdates: swiftPackageUpdates)
    }

    private static func mergeDependencies(
        packageDescription: PackageDescription,
        resolvedPackage: ResolvedPackage,
        swiftPackageUpdates: [SwiftPackageUpdate]
    ) throws -> [Dependency] {
        try resolvedPackage.dependencies.map { resolvedDependency in
            let packageDependency = packageDescription.dependencies.first { $0.url == resolvedDependency.url }
            let swiftPackageUpdate = swiftPackageUpdates.first { $0.name == resolvedDependency.name }
            let latestRelease = try Version.getLatestRelease(from: resolvedDependency.url)
            let update = try Update.getUpdate(
                name: resolvedDependency.name,
                currentVersion: resolvedDependency.version.version,
                swiftPackageUpdate: swiftPackageUpdate,
                latestRelease: latestRelease
            )
            return Dependency(
                name: resolvedDependency.name,
                url: resolvedDependency.url,
                requirement: packageDependency?.requirement,
                resolvedVersion: resolvedDependency.version,
                update: update)
        }
    }

    func update(in folder: URL) throws {
        try update?.execute(for: self, in: folder)
    }
}

extension Dependency: CustomStringConvertible {

    public var description: String {
        """
        \(name.bold) \(url.absoluteString.italic)
        Required: \(requirement == nil ? "No" : "\(requirement!)")
        Resolved: \(resolvedVersion)
        Update: \(update == nil ? "No update available".green : "\(update!)")
        """
    }
}

extension DependencyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .loadingFailed(error):
            return "Could not get package data, swift package dump-package failed: \(error)"
        case let .parsingFailed(error, packageData):
            return "Could not parse package data: \(error)\n\nPackage Data: \(packageData)"
        }
    }
}
