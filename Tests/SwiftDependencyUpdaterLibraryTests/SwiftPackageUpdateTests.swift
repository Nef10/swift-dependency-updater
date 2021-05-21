import Rainbow
import Releases
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class SwiftPackageUpdateTests: XCTestCase {

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

}
