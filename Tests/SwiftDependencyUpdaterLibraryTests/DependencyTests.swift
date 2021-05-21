import Rainbow
import Releases
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class DependencyTests: XCTestCase {

     func testDependencyErrorString() {
        XCTAssertEqual("\(DependencyError.loadingFailed("abc").localizedDescription)", "Could not get package data, swift package dump-package failed: abc")
        XCTAssertEqual("\(DependencyError.parsingFailed("abc", "def").localizedDescription)", "Could not parse package data: abc\n\nPackage Data: def")
    }

    func testDependencyString() {
        let decoder = JSONDecoder()
        let data = "{\"revision\": \"abc\", \"branch\": null, \"version\": \"1.2.3\"}".data(using: .utf8)!
        let resolvedVersion = try! decoder.decode(ResolvedVersion.self, from: data)
        let update = Update.skipped
        let requirement = DependencyRequirement.exact(version: try! Version(string: "1.2.3"))

        let originalValue = Rainbow.enabled
        Rainbow.enabled = false

        var dependency = Dependency(name: "ABC", url: URL(string: "https://github.com/Name/abc.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: nil)
        XCTAssertEqual("\(dependency)", "ABC https://github.com/Name/abc.git\nRequired: No\nResolved: \(resolvedVersion)\nUpdate: No update available")

        dependency = Dependency(name: "ABC", url: URL(string: "https://github.com/Name/abc.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)
        XCTAssertEqual("\(dependency)", "ABC https://github.com/Name/abc.git\nRequired: No\nResolved: \(resolvedVersion)\nUpdate: \(update)")

        dependency = Dependency(name: "ABC", url: URL(string: "https://github.com/Name/abc.git")!, requirement: requirement, resolvedVersion: resolvedVersion, update: nil)
        XCTAssertEqual("\(dependency)", "ABC https://github.com/Name/abc.git\nRequired: \(requirement)\nResolved: \(resolvedVersion)\nUpdate: No update available")

        Rainbow.enabled = originalValue
    }

}
