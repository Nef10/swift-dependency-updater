import Foundation
import Releases

enum UpdateError: Error, Equatable {
    case resolvedVersionNotFound(String, Version, Version)
    case updatedVersionNotFound(String, Version, Version)
}

enum Update: Equatable {

    case withoutChangingRequirements(Version)
    case withChangingRequirements(Version)
    case skipped

    static func getUpdate(name: String, currentVersion: Version?, swiftPackageUpdate: SwiftPackageUpdate?, latestRelease: Version?) throws -> Update? {
        guard let currentVersion = currentVersion else {
            return .skipped
        }
        if let latestRelease = latestRelease, currentVersion != latestRelease {
            if currentVersion < latestRelease {
                if let update = swiftPackageUpdate {
                    if update.newVersion < latestRelease {
                        return .withChangingRequirements(latestRelease)
                    } else if update.newVersion > latestRelease {
                        throw UpdateError.updatedVersionNotFound(name, update.newVersion, latestRelease)
                    } else {
                        return .withoutChangingRequirements(update.newVersion)
                    }
                } else {
                    return .withChangingRequirements(latestRelease)
                }
            } else {
                throw UpdateError.resolvedVersionNotFound(name, currentVersion, latestRelease)
            }
        } else if let update = swiftPackageUpdate {
            return .withoutChangingRequirements(update.newVersion)
        } else {
            return nil
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
