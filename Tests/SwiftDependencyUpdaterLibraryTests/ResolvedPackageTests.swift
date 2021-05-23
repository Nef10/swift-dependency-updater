import Releases
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class ResolvedPackageTests: XCTestCase {

    func testEmptyFolder() {
        let folder = emptyFolderURL()
        #if os(Linux)
        assert(
            try ResolvedPackage.loadResolvedPackage(from: folder),
            throws: ResolvedPackageError.readingFailed("The operation could not be completed. No such file or directory")
        )
        #else
        assert(
            try ResolvedPackage.loadResolvedPackage(from: folder),
            throws: ResolvedPackageError.readingFailed("The file “Package.resolved” couldn’t be opened because there is no such file.")
        )
        #endif
    }

    func testInvalidFile() {
        let folder = emptyFolderURL()
        let file = temporaryFileURL(in: folder, name: "Package.resolved")
        createFile(at: file, content: "\n")
        #if os(Linux)
        assert(
            try ResolvedPackage.loadResolvedPackage(from: folder),
            throws: ResolvedPackageError.parsingFailed("The operation could not be completed. The data isn’t in the correct format.", "\n")
        )
        #else
        assert(
            try ResolvedPackage.loadResolvedPackage(from: folder),
            throws: ResolvedPackageError.parsingFailed("The data couldn’t be read because it isn’t in the correct format.", "\n")
        )
        #endif
    }

    func testParsing() {
        let folder = emptyFolderURL()
        let file = temporaryFileURL(in: folder, name: "Package.resolved")
        createFile(at: file, content: TestUtils.packageResolvedFileContent)
        let result = try! ResolvedPackage.loadResolvedPackage(from: folder)
        XCTAssertEqual(result.dependencies.count, 3)

        XCTAssertEqual(result.dependencies[0].name, "a")
        XCTAssertEqual(result.dependencies[0].url, URL(string: "https://github.com/a/a.git")!)
        XCTAssertNil(result.dependencies[0].version.branch)
        XCTAssertEqual(result.dependencies[0].version.revision, "abc")
        XCTAssertNil(result.dependencies[0].version.version)

        XCTAssertEqual(result.dependencies[1].name, "b")
        XCTAssertEqual(result.dependencies[1].url, URL(string: "https://github.com/b/b")!)
        XCTAssertNil(result.dependencies[1].version.branch)
        XCTAssertEqual(result.dependencies[1].version.revision, "def")
        XCTAssertEqual(result.dependencies[1].version.version, try! Version(string: "0.0.0"))

        XCTAssertEqual(result.dependencies[2].name, "c")
        XCTAssertEqual(result.dependencies[2].url, URL(string: "https://github.com/c/c.git")!)
        XCTAssertEqual(result.dependencies[2].version.branch, "main")
        XCTAssertEqual(result.dependencies[2].version.revision, "ghi")
        XCTAssertNil(result.dependencies[2].version.version)
    }

    func testResolvedVersionString() {
        let decoder = JSONDecoder()

        var data = "{\"revision\": \"abc\", \"branch\": null, \"version\": null}".data(using: .utf8)!
        var version = try! decoder.decode(ResolvedVersion.self, from: data)
        XCTAssertEqual("\(version)", "abc")

        data = "{\"revision\": \"abc\", \"branch\": \"main\", \"version\": null}".data(using: .utf8)!
        version = try! decoder.decode(ResolvedVersion.self, from: data)
        XCTAssertEqual("\(version)", "abc (branch: main)")

        data = "{\"revision\": \"abc\", \"branch\": null, \"version\": \"0.0.0\"}".data(using: .utf8)!
        version = try! decoder.decode(ResolvedVersion.self, from: data)
        XCTAssertEqual("\(version)", "0.0.0 (abc)")

        data = "{\"revision\": \"abc\", \"branch\": \"main\", \"version\": \"0.0.0\"}".data(using: .utf8)!
        version = try! decoder.decode(ResolvedVersion.self, from: data)
        XCTAssertEqual("\(version)", "0.0.0 (abc, branch: main)")
    }

    func testVersionNumberOrRevision() {
        let decoder = JSONDecoder()

        var data = "{\"revision\": \"abc\", \"branch\": null, \"version\": null}".data(using: .utf8)!
        var version = try! decoder.decode(ResolvedVersion.self, from: data)
        XCTAssertEqual("\(version.versionNumberOrRevision)", "abc")

        data = "{\"revision\": \"abc\", \"branch\": \"main\", \"version\": \"1.2.3\"}".data(using: .utf8)!
        version = try! decoder.decode(ResolvedVersion.self, from: data)
        XCTAssertEqual("\(version.versionNumberOrRevision)", "1.2.3")
    }

    func testResolvedPackageErrorString() {
        XCTAssertEqual("\(ResolvedPackageError.readingFailed("abc").localizedDescription)", "Could not read Package.resolved file: abc")
        XCTAssertEqual("\(ResolvedPackageError.parsingFailed("abc", "def").localizedDescription)", "Could not parse package data: abc\n\nPackage Data: def")
    }

}
