import Rainbow
import Releases
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class UpdateTests: XCTestCase {

    func testGetUpdateEmptyVersion() {
        let swiftPackageUpdate = SwiftPackageUpdate(name: "ABC", oldVersion: try! Version(string: "0.1.2"), newVersion: try! Version(string: "1.2.3"))
        let latestRelease = try! Version(string: "0.1.2")

        var result = try! Update.getUpdate(name: "ABC", currentVersion: nil, swiftPackageUpdate: nil, latestRelease: nil, requirement: true)
        XCTAssertEqual(result, .skipped)
        result = try! Update.getUpdate(name: "ABC", currentVersion: nil, swiftPackageUpdate: swiftPackageUpdate, latestRelease: nil, requirement: true)
        XCTAssertEqual(result, .skipped)
        result = try! Update.getUpdate(name: "ABC", currentVersion: nil, swiftPackageUpdate: nil, latestRelease: latestRelease, requirement: true)
        XCTAssertEqual(result, .skipped)
        result = try! Update.getUpdate(name: "ABC", currentVersion: nil, swiftPackageUpdate: swiftPackageUpdate, latestRelease: latestRelease, requirement: true)
        XCTAssertEqual(result, .skipped)
    }

    func testGetUpdateNoUpdate() {
        let version = try! Version(string: "1.2.3")
        let result = try! Update.getUpdate(name: "ABC", currentVersion: version, swiftPackageUpdate: nil, latestRelease: nil, requirement: true)
        XCTAssertNil(result)
    }

    func testGetUpdateSwiftPackageUpdate() {
        let oldVersion = try! Version(string: "0.1.2")
        let newVersion = try! Version(string: "1.2.3")
        let swiftPackageUpdate = SwiftPackageUpdate(name: "ABC", oldVersion: oldVersion, newVersion: newVersion)

        let result = try! Update.getUpdate(name: "ABC", currentVersion: oldVersion, swiftPackageUpdate: swiftPackageUpdate, latestRelease: nil, requirement: true)
        XCTAssertEqual(result, Update.withoutChangingRequirements(newVersion))
    }

    func testGetUpdateLatestRelease() {
        let oldVersion = try! Version(string: "0.1.2")
        let newVersion = try! Version(string: "1.2.3")

        let result = try! Update.getUpdate(name: "ABC", currentVersion: oldVersion, swiftPackageUpdate: nil, latestRelease: newVersion, requirement: true)
        XCTAssertEqual(result, Update.withChangingRequirements(newVersion))
    }

    func testGetUpdateLatestReleaseError() {
        let newVersion = try! Version(string: "0.1.2")
        let oldVersion = try! Version(string: "1.2.3")

        assert(
            try Update.getUpdate(name: "ABC", currentVersion: oldVersion, swiftPackageUpdate: nil, latestRelease: newVersion, requirement: true),
            throws: UpdateError.resolvedVersionNotFound("ABC", oldVersion, newVersion)
        )
    }

    func testGetUpdateLatestReleaseAndSwiftPackageUpdateChangingRequirements() {
        let latestRelease = try! Version(string: "0.1.4")
        let newVersion = try! Version(string: "0.1.3")
        let oldVersion = try! Version(string: "0.1.2")
        let swiftPackageUpdate = SwiftPackageUpdate(name: "ABC", oldVersion: oldVersion, newVersion: newVersion)

        let result = try! Update.getUpdate(name: "ABC", currentVersion: oldVersion, swiftPackageUpdate: swiftPackageUpdate, latestRelease: latestRelease, requirement: true)
        XCTAssertEqual(result, Update.withChangingRequirements(latestRelease))
    }

    func testGetUpdateLatestReleaseAndSwiftPackageUpdateWithoutChangingRequirements() {
        let latestRelease = try! Version(string: "0.1.4")
        let newVersion = try! Version(string: "0.1.4")
        let oldVersion = try! Version(string: "0.1.2")
        let swiftPackageUpdate = SwiftPackageUpdate(name: "ABC", oldVersion: oldVersion, newVersion: newVersion)

        let result = try! Update.getUpdate(name: "ABC", currentVersion: oldVersion, swiftPackageUpdate: swiftPackageUpdate, latestRelease: latestRelease, requirement: true)
        XCTAssertEqual(result, Update.withoutChangingRequirements(latestRelease))
    }

    func testGetUpdateLatestReleaseAndSwiftPackageUpdateError() {
        let newVersion = try! Version(string: "0.1.4")
        let latestRelease = try! Version(string: "0.1.3")
        let oldVersion = try! Version(string: "0.1.2")
        let swiftPackageUpdate = SwiftPackageUpdate(name: "ABC", oldVersion: oldVersion, newVersion: newVersion)

        assert(
            try Update.getUpdate(name: "ABC", currentVersion: oldVersion, swiftPackageUpdate: swiftPackageUpdate, latestRelease: latestRelease, requirement: true),
            throws: UpdateError.updatedVersionNotFound("ABC", newVersion, latestRelease)
        )
    }

     func testUpdateErrorString() {
        XCTAssertEqual(
            "\(UpdateError.resolvedVersionNotFound("abc", try! Version(string: "1.2.3"), try! Version(string: "0.1.2")).localizedDescription)",
            "The resolved version of abc is 1.2.3, but the newest release on the remote is 0.1.2")
        XCTAssertEqual(
            "\(UpdateError.updatedVersionNotFound("abc", try! Version(string: "1.2.3"), try! Version(string: "0.1.2")).localizedDescription)",
            "The swift package manager wants to update the version of abc to 1.2.3, but the newest release on the remote is 0.1.2")
    }

    func testUpdateString() {
        let originalValue = Rainbow.enabled
        Rainbow.enabled = false
        XCTAssertEqual("\(Update.withoutChangingRequirements(try! Version(string: "0.1.2")))", "0.1.2 (Without changing requirements)")
        XCTAssertEqual("\(Update.withChangingRequirements(try! Version(string: "1.2.3")))", "1.2.3 (Requires changing requirements)")
        XCTAssertEqual("\(Update.skipped)", "Current version is not a release version, skipping")
        Rainbow.enabled = originalValue
    }

}
