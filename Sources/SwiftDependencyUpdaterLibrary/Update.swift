import Foundation
import Releases
import ShellOut

enum UpdateError: Error, Equatable {
    case resolvedVersionNotFound(String, Version, Version)
    case updatedVersionNotFound(String, Version, Version)
}

enum Update: Equatable {

    case withoutChangingRequirements(Version)
    case withChangingRequirements(Version)
    case withoutRequirement(Version)
    case skipped

    static func getUpdate(name: String, currentVersion: Version?, swiftPackageUpdate: SwiftPackageUpdate?, latestRelease: Version?, requirement: Bool) throws -> Self? {
        guard let currentVersion else {
            return .skipped
        }
        if let latestRelease, currentVersion != latestRelease {
            if currentVersion < latestRelease {
                if let update = swiftPackageUpdate {
                    if update.newVersion < latestRelease {
                        return .withChangingRequirements(latestRelease)
                    }
                    if update.newVersion > latestRelease {
                        throw UpdateError.updatedVersionNotFound(name, update.newVersion, latestRelease)
                    }
                    return .withoutChangingRequirements(update.newVersion)
                }
                if !requirement {
                    return .withoutRequirement(latestRelease)
                }
                return .withChangingRequirements(latestRelease)
            }
            throw UpdateError.resolvedVersionNotFound(name, currentVersion, latestRelease)
        }
        if let update = swiftPackageUpdate {
            if !requirement {
                return .withoutRequirement(update.newVersion)
            }
            return .withoutChangingRequirements(update.newVersion)
        }
        return nil
    }

    func execute(for dependency: Dependency, in folder: URL) throws {
        switch self {
        case let .withChangingRequirements(version):
            print("Updating \(dependency.name): \(dependency.resolvedVersion.versionNumberOrRevision) -> \(version)".bold)
            let swiftPackage = SwiftPackage(in: folder)
            let packageUpdate = try swiftPackage.performUpdate(self, of: dependency)
            print("Updated Package.swift".green)
            if packageUpdate {
                try shellOut(to: "swift", arguments: ["package", "--package-path", "\"\(folder.path)\"", "update", dependency.name ])
                print("Resolved to new version".green)
            } else {
                try shellOut(to: "swift", arguments: ["package", "--package-path", "\"\(folder.path)\"", "update", "resolve", ])
                print("Resolved Version".green)
            }
        case let .withoutChangingRequirements(version), let .withoutRequirement(version):
            print("Updating \(dependency.name): \(dependency.resolvedVersion.versionNumberOrRevision) -> \(version)".bold)
            try shellOut(to: "swift", arguments: ["package", "--package-path", "\"\(folder.path)\"", "update", dependency.name, ])
            if case .withoutRequirement = self {
                print("Tried to resolve to new version".green + " - if this is an indirect dependency with a version restriction from another dependency, it may not update.")
            } else {
                print("Resolved to new version".green)
            }
        default:
            // Do nothing
            break
        }
    }
}

extension Update: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .withoutChangingRequirements(version):
            return "\("\(version)".yellow) (Without changing requirements)"
        case let .withChangingRequirements(version):
            return "\("\(version)".red) (Requires changing requirements)"
        case let .withoutRequirement(version):
            return "\("\(version)".lightYellow) (Without requirement)"
        case .skipped:
            return "Current version is not a release version, skipping".yellow
        }
    }

}

extension UpdateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .resolvedVersionNotFound(name, resolved, remote):
            return "The resolved version of \(name) is \(resolved), but the newest release on the remote is \(remote)"
        case let .updatedVersionNotFound(name, updated, remote):
            return "The swift package manager wants to update the version of \(name) to \(updated), but the newest release on the remote is \(remote)"
        }
    }
}
