@testable import SwiftDependencyUpdaterLibrary
import XCTest

final class CollectionTests: XCTestCase {

    func testSafeArray() {
        var array = [String]()
        XCTAssertNil(array[safe: 0])
        array.append("value")
        XCTAssertEqual(array[safe: 0], "value")
        XCTAssertNil(array[safe: 1])
    }

}
