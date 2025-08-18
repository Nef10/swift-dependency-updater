@testable import SwiftDependencyUpdaterLibrary
import XCTest

final class HelpTests: XCTestCase {

   func testHelp() {
        let result = outputFromExecutionWith(arguments: ["--help"])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.errorOutput.isEmpty)
        XCTAssertTrue(result.output.contains("OVERVIEW: A CLI tool to update Swift Pacakge Manager dependencies"))
        XCTAssertTrue(result.output.contains("USAGE: swift-dependency-updater <subcommand>"))
        XCTAssertTrue(result.output.contains("See 'swift-dependency-updater help <subcommand>' for detailed help."))
    }

}
