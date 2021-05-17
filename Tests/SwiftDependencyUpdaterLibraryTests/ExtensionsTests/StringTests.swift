@testable import SwiftDependencyUpdaterLibrary
import XCTest

class StringTests: XCTestCase {

    func testMatchingStrings_multipleGroups() {
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: "^\\s+([^\\s]+:[^\\s]+)\\s+(-?[0-9]+(.[0-9]+)?)\\s+([^\\s]+)\\s*(;.*)?$", options: [])
        let results = "  Assets:Checking 1.00 EUR".matchingStrings(regex: regex)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0], ["  Assets:Checking 1.00 EUR", "Assets:Checking", "1.00", ".00", "EUR", ""])
    }

    func testMatchingStrings_multipleResults() {
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: "\\d\\D\\d", options: [])
        let results = "0a01b1".matchingStrings(regex: regex)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0], ["0a0"])
        XCTAssertEqual(results[1], ["1b1"])
    }

}
