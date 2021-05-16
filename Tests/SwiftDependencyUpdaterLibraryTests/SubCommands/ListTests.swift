@testable import SwiftDependencyUpdaterLibrary
import XCTest

class ListTests: XCTestCase {

    func testFileInsteadOfFolder() {
        let url = emptyFileURL()
        let result = outputFromExecutionWith(arguments: ["list", url.path])
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssertEqual(result.output, "Folder argument must be a directory.")
    }

    func testEmptyFolder() {
        let url = emptyFolderURL()
        let result = outputFromExecutionWith(arguments: ["list", url.path])
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssertEqual(result.output, "Could not get package data, swift package dump-package failed: error: root manifest not found")
    }

}
