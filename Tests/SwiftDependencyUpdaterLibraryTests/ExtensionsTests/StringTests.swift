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

    func testMatchingStrings_extendedGraphemeClusters() {
        var regex = try! NSRegularExpression(pattern: "[0-9]", options: [])
        var results = "🇩🇪€4€9".matchingStrings(regex: regex)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0], ["4"])
        XCTAssertEqual(results[1], ["9"])

        regex = try! NSRegularExpression(pattern: "🇩🇪", options: [])
        results = "🇩🇪€4€9".matchingStrings(regex: regex)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0], ["🇩🇪"])
    }

    func testMatchingStringsWithRange_multipleGroups() {
        let regex = try! NSRegularExpression(pattern: "^\\s+([^\\s]+:[^\\s]+)\\s+(-?[0-9]+(.[0-9]+)?)\\s+([^\\s]+)\\s*(;.*)?$", options: [])
        let string = "  Assets:Checking 1.00 EUR"
        let results = string.matchingStringsWithRange(regex: regex)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0][0]?.string, "  Assets:Checking 1.00 EUR")
        XCTAssertEqual(results[0][1]?.string, "Assets:Checking")
        XCTAssertEqual(results[0][2]?.string, "1.00")
        XCTAssertEqual(results[0][3]?.string, ".00")
        XCTAssertEqual(results[0][4]?.string, "EUR")
        XCTAssertNil(results[0][5])

        XCTAssertEqual(results[0][0]?.range, string.startIndex..<string.index(string.startIndex, offsetBy: 26))
        XCTAssertEqual(results[0][1]?.range, string.index(string.startIndex, offsetBy: 2)..<string.index(string.startIndex, offsetBy: 17))
        XCTAssertEqual(results[0][2]?.range, string.index(string.startIndex, offsetBy: 18)..<string.index(string.startIndex, offsetBy: 22))
        XCTAssertEqual(results[0][3]?.range, string.index(string.startIndex, offsetBy: 19)..<string.index(string.startIndex, offsetBy: 22))
        XCTAssertEqual(results[0][4]?.range, string.index(string.startIndex, offsetBy: 23)..<string.index(string.startIndex, offsetBy: 26))
    }

     func testMatchingStringsWithRange_multipleResults() {
        let regex = try! NSRegularExpression(pattern: "\\d\\D\\d", options: [])
        let string = "0a01b1"
        let results = string.matchingStringsWithRange(regex: regex)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0][0]?.string, "0a0")
        XCTAssertEqual(results[1][0]?.string, "1b1")

        let middle = string.index(string.startIndex, offsetBy: 3)
        XCTAssertEqual(results[0][0]?.range, string.startIndex..<middle)
        XCTAssertEqual(results[1][0]?.range, middle..<string.endIndex)
    }

}
