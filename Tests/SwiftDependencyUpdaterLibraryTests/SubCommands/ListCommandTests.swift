@testable import SwiftDependencyUpdaterLibrary
import XCTest

final class ListCommandTests: XCTestCase {

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
        let errors = [
            "Could not get package data, swift package dump-package failed: error: Could not find Package.swift in this directory or any of its parent directories.",
            "Could not get package data, swift package dump-package failed: error: root manifest not found"
        ]
        XCTAssert(errors.contains(result.output), "Received \(result.output) instead of expected error")
    }

    func testInvalidPackage() {
        let folder = emptyFolderURL()
        let packageSwift = temporaryFileURL(in: folder, name: "Package.swift")
        createFile(at: packageSwift, content: "// swift-tools-version:5.4")
        let packageResolved = temporaryFileURL(in: folder, name: "Package.resolved")
        createFile(at: packageResolved, content: TestUtils.emptyPackageResolvedFileContent)
        let result = outputFromExecutionWith(arguments: ["list", folder.path])
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssert(result.output.contains("Could not get package data, swift package dump-package failed"))
    }

    func testNoDependencies() {
        let folder = createEmptySwiftPackage()
        let result = outputFromExecutionWith(arguments: ["list", folder.path])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssertEqual(result.output, "No dependencies found.")
    }

    func testNoDependenciesUpdatesOnly() {
        let folder = createEmptySwiftPackage()
        let result = outputFromExecutionWith(arguments: ["list", folder.path, "--updates-only"])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssertEqual(result.output, "Everything up-to-date!")
    }

    func testNoDependenciesExcludeIndirect() {
        let folder = createEmptySwiftPackage()
        let result = outputFromExecutionWith(arguments: ["list", folder.path, "--exclude-indirect"])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssertEqual(result.output, "No dependencies found.")
    }

}
