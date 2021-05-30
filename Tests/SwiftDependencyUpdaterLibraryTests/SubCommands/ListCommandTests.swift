@testable import SwiftDependencyUpdaterLibrary
import XCTest

class ListCommandTests: XCTestCase {

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

    func createEmptySwiftPackage() -> URL {
        let folder = emptyFolderURL()
        let packageSwift = temporaryFileURL(in: folder, name: "Package.swift")
        createFile(at: packageSwift, content: TestUtils.emptyPackageSwiftFileContent)
        let packageResolved = temporaryFileURL(in: folder, name: "Package.resolved")
        createFile(at: packageResolved, content: TestUtils.emptyPackageResolvedFileContent)
        let sourceFile = temporaryFileURL(in: folder.appendingPathComponent("Sources/Name"), name: "Name.swift")
        createFile(at: sourceFile, content: "")

        return folder
    }

}
