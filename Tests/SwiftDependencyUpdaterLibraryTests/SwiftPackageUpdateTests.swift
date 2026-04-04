import Rainbow
import Releases
@testable import SwiftDependencyUpdaterLibrary
import XCTest

final class SwiftPackageUpdateTests: XCTestCase {

    func testSwiftPackageUpdateErrorString() {
        XCTAssertEqual("\(SwiftPackageUpdateError.loadingFailed("abc").localizedDescription)", "Could not get package update data, swift package update failed: abc")
        XCTAssertEqual(
            "\(SwiftPackageUpdateError.parsingNumberFailed("abc").localizedDescription)",
            "Could not parse number of package updates from the swift package update output: abc")
        XCTAssertEqual(
            "\(SwiftPackageUpdateError.parsingNumberMismatch("abc", 1, 3).localizedDescription)",
            "The number of package updates (1) from the swift package update output mismatches the number of updates parsed (3). Output: abc")
        XCTAssertEqual(
            "\(SwiftPackageUpdateError.parsingDependencyFailed("abc", [""]).localizedDescription)",
            "Could not parse a dependency ([\"\"]) from the swift package update output: abc")
    }

    func testSwiftPackageUpdateString() {
        let originalValue = Rainbow.enabled
        Rainbow.enabled = false

        let swiftPackageUpdate = SwiftPackageUpdate(name: "ABC", oldVersion: try! Version(string: "0.1.2"), newVersion: try! Version(string: "0.1.3"))
        XCTAssertEqual("\(swiftPackageUpdate)", "0.1.2 -> 0.1.3 (Without changing requirements)")

        Rainbow.enabled = originalValue
    }

    func testCheckUpdatesEmptyFolder() {
        let folder = emptyFolderURL()
        assert(
            try SwiftPackageUpdate.checkUpdates(in: folder),
            throws: [
                SwiftPackageUpdateError.loadingFailed("error: root manifest not found"),
                SwiftPackageUpdateError.loadingFailed("error: Could not find Package.swift in this directory or any of its parent directories.")
            ]
        )
    }

    func testCheckUpdatesEmptySwiftPackage() {
        let folder = createEmptySwiftPackage()
        XCTAssert(try! SwiftPackageUpdate.checkUpdates(in: folder).isEmpty)
    }

    func testParseOutputOldFormatNoUpdates() {
        let output = "0 dependencies have changed."
        XCTAssert(try! SwiftPackageUpdate.parseOutput(output).isEmpty)
    }

    func testParseOutputOldFormatSingleUpdate() {
        let output = "1 dependency has changed:\n~ mypackage 1.0.0 -> mypackage 1.1.0"
        let result = try! SwiftPackageUpdate.parseOutput(output)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "mypackage")
        XCTAssertEqual(result[0].oldVersion, try! Version(string: "1.0.0"))
        XCTAssertEqual(result[0].newVersion, try! Version(string: "1.1.0"))
    }

    func testParseOutputOldFormatMultipleUpdates() {
        let output = "2 dependencies have changed:\n~ packageA 1.0.0 -> packageA 1.1.0\n~ packageB 2.0.0 -> packageB 2.3.0"
        let result = try! SwiftPackageUpdate.parseOutput(output)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "packageA")
        XCTAssertEqual(result[0].oldVersion, try! Version(string: "1.0.0"))
        XCTAssertEqual(result[0].newVersion, try! Version(string: "1.1.0"))
        XCTAssertEqual(result[1].name, "packageB")
        XCTAssertEqual(result[1].oldVersion, try! Version(string: "2.0.0"))
        XCTAssertEqual(result[1].newVersion, try! Version(string: "2.3.0"))
    }

    func testParseOutputNewFormatNoUpdates() {
        let output = "[Dry-run] 0 dependencies would change."
        XCTAssert(try! SwiftPackageUpdate.parseOutput(output).isEmpty)
    }

    func testParseOutputNewFormatSingleUpdate() {
        let output = "[Dry-run] 1 dependency would change:\n~ mypackage 1.0.0 -> mypackage 1.1.0"
        let result = try! SwiftPackageUpdate.parseOutput(output)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "mypackage")
        XCTAssertEqual(result[0].oldVersion, try! Version(string: "1.0.0"))
        XCTAssertEqual(result[0].newVersion, try! Version(string: "1.1.0"))
    }

    func testParseOutputNewFormatMultipleUpdates() {
        let output = "[Dry-run] 2 dependencies would change:\n~ packageA 1.0.0 -> packageA 1.1.0\n~ packageB 2.0.0 -> packageB 2.3.0"
        let result = try! SwiftPackageUpdate.parseOutput(output)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "packageA")
        XCTAssertEqual(result[0].oldVersion, try! Version(string: "1.0.0"))
        XCTAssertEqual(result[0].newVersion, try! Version(string: "1.1.0"))
        XCTAssertEqual(result[1].name, "packageB")
        XCTAssertEqual(result[1].oldVersion, try! Version(string: "2.0.0"))
        XCTAssertEqual(result[1].newVersion, try! Version(string: "2.3.0"))
    }

    func testParseOutputInvalidFormat() {
        assert(
            try SwiftPackageUpdate.parseOutput("something unexpected"),
            throws: SwiftPackageUpdateError.parsingNumberFailed("something unexpected")
        )
    }

}
