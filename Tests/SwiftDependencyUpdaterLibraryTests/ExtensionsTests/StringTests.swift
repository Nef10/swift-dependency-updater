@testable import SwiftDependencyUpdaterLibrary
import XCTest

class StringTests: XCTestCase {

    func testMatchingStrings_multipleGroups() {
        let regex = try! NSRegularExpression(pattern: "^\\s+([^\\s]+:[^\\s]+)\\s+(-?[0-9]+(.[0-9]+)?)\\s+([^\\s]+)\\s*(;.*)?$", options: [])
        let results = "  Assets:Checking 1.00 EUR".matchingStrings(regex: regex)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0], ["  Assets:Checking 1.00 EUR", "Assets:Checking", "1.00", ".00", "EUR", ""])
    }

    func testMatchingStrings_multipleResults() {
        let regex = try! NSRegularExpression(pattern: "\\d\\D\\d", options: [])
        let results = "0a01b1".matchingStrings(regex: regex)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0], ["0a0"])
        XCTAssertEqual(results[1], ["1b1"])
    }

    func testMatchingStringsWithRange_multipleGroups() {
        let regex = try! NSRegularExpression(pattern: "^\\s+([^\\s]+:[^\\s]+)\\s+(-?[0-9]+(.[0-9]+)?)\\s+([^\\s]+)\\s*(;.*)?$", options: [])
        let results = "  Assets:Checking 1.00 EUR".matchingStringsWithRange(regex: regex)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0][0]?.string, "  Assets:Checking 1.00 EUR")
        XCTAssertEqual(results[0][1]?.string, "Assets:Checking")
        XCTAssertEqual(results[0][2]?.string, "1.00")
        XCTAssertEqual(results[0][3]?.string, ".00")
        XCTAssertEqual(results[0][4]?.string, "EUR")
        XCTAssertNil(results[0][5])
        XCTAssertEqual(results[0][0]?.range, NSRange(location: 0, length: 26))
        XCTAssertEqual(results[0][1]?.range, NSRange(location: 2, length: 15))
        XCTAssertEqual(results[0][2]?.range, NSRange(location: 18, length: 4))
        XCTAssertEqual(results[0][3]?.range, NSRange(location: 19, length: 3))
        XCTAssertEqual(results[0][4]?.range, NSRange(location: 23, length: 3))
    }

     func testMatchingStringsWithRange_multipleResults() {
        let regex = try! NSRegularExpression(pattern: "\\d\\D\\d", options: [])
        let results = "0a01b1".matchingStringsWithRange(regex: regex)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0][0]?.string, "0a0")
        XCTAssertEqual(results[1][0]?.string, "1b1")
        XCTAssertEqual(results[0][0]?.range, NSRange(location: 0, length: 3))
        XCTAssertEqual(results[1][0]?.range, NSRange(location: 3, length: 3))
    }

}
