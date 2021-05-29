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
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
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

    func testBranchNameForUpdate() {
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
        let url = URL(string: "https://github.com/Name/abc.git")!

        let dependency = Dependency(name: "test space&special1%characters", url: url, requirement: nil, resolvedVersion: resolvedVersion, update: nil)
        XCTAssertEqual("\(dependency.branchNameForUpdate)", "swift-dependency-updater/test-space-special1-characters")
    }

     func testChangeDescription() {
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
        let url = URL(string: "https://github.com/Name/abc.git")!

        var dependency = Dependency(name: "ABC", url: url, requirement: nil, resolvedVersion: resolvedVersion, update: nil)
        XCTAssertEqual("\(dependency.changeDescription)", "")

        dependency = Dependency(name: "ABC", url: url, requirement: nil, resolvedVersion: resolvedVersion, update: .skipped)
        XCTAssertEqual("\(dependency.changeDescription)", "")

        dependency = Dependency(name: "ABC", url: url, requirement: nil, resolvedVersion: resolvedVersion, update: .withoutChangingRequirements(try! Version(string: "1.4.3")))
        XCTAssertEqual("\(dependency.changeDescription)", "Bump ABC from 1.2.3 to 1.4.3")

        dependency = Dependency(name: "ABC", url: url, requirement: nil, resolvedVersion: resolvedVersion, update: .withChangingRequirements(try! Version(string: "2.0.3")))
        XCTAssertEqual("\(dependency.changeDescription)", "Bump ABC from 1.2.3 to 2.0.3")
    }

}
