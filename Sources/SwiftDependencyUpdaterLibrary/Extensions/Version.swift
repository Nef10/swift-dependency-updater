import Foundation
import Releases

enum ReleaseError: Error {
    case loadingFailed(URL, String)
    case noReleaseFound(URL)
}

extension Version {

    static func getLatestRelease(from url: URL) throws -> Version {
        guard var version = try loadLatestRelease(from: url) else {
            throw ReleaseError.noReleaseFound(url)
        }
        version.prefix = nil
        return version
    }

    static func loadLatestRelease(from url: URL) throws -> Version? {
        var url = url
        if url.pathExtension != "git" {
            url.appendPathExtension("git")
        }
        do {
            let allReleases = try Releases.versions(for: url)
            let relevantReleases = allReleases.withoutPreReleases()
            return relevantReleases.max()
        } catch {
            throw ReleaseError.loadingFailed(url, error.localizedDescription)
        }
    }
}

extension ReleaseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .loadingFailed(url, error):
            return "Could not get release data from URL \(url): \(error)"
        case let .noReleaseFound(url):
            return "No release found for URL: \(url)"
        }
    }
}
