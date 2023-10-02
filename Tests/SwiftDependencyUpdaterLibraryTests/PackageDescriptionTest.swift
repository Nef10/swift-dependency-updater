import Releases
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class PackageDescriptionTest: XCTestCase {

    func testEmptyFolder() {
        let folder = emptyFolderURL()

        assert(
            try PackageDescriptionFactory.loadPackageDescription(from: folder),
            throws: [
                PackageDescriptionError.loadingFailed("error: root manifest not found"),
                PackageDescriptionError.loadingFailed("error: Could not find Package.swift in this directory or any of its parent directories.")
            ]
        )
    }

    func testInvalidFile() {
        var caughtError: Error?
        let folder = emptyFolderURL()
        let file = temporaryFileURL(in: folder, name: "Package.swift")
        createFile(at: file, content: "// swift-tools-version:5.4.0\n")

        XCTAssertThrowsError(try PackageDescriptionFactory.loadPackageDescription(from: folder)) {
            caughtError = $0
        }

        guard let error = caughtError as? PackageDescriptionError, case let .loadingFailed(description) = error else {
            XCTFail("Unexpected error, got \(type(of: caughtError!)) \(caughtError!)) instead of PackageDescriptionError.loadingFailed")
            return
        }
        let errors = [
            "Missing or empty JSON output from manifest compilation",
            "\(folder.path): error: malformed"
        ]

        XCTAssert(errors.contains { description.contains($0) }, "Received \(description) instead of expected error")
    }

    func testParsing() throws {
        let folder = emptyFolderURL()
        let file = temporaryFileURL(in: folder, name: "Package.swift")
        createFile(at: file, content: TestUtils.packageSwiftFileContent)
        let result = try PackageDescriptionFactory.loadPackageDescription(from: folder)
        XCTAssertEqual(result.dependencies.count, 8)

        XCTAssertEqual(result.dependencies[0].name, "a")
        XCTAssertEqual(result.dependencies[0].url, URL(string: "https://github.com/a/a")!)
        XCTAssertEqual(result.dependencies[0].requirement, .range(lowerBound: try! Version(string: "0.3.1"), upperBound: try! Version(string: "0.4.0")))

        XCTAssertEqual(result.dependencies[1].name, "b")
        XCTAssertEqual(result.dependencies[1].url, URL(string: "https://github.com/b/b.git")!)
        XCTAssertEqual(result.dependencies[1].requirement, .range(lowerBound: try! Version(string: "2.3.1"), upperBound: try! Version(string: "3.0.0")))

        XCTAssertEqual(result.dependencies[2].name, "c")
        XCTAssertEqual(result.dependencies[2].url, URL(string: "https://github.com/c/c.git")!)
        XCTAssertEqual(result.dependencies[2].requirement, .exact(version: try! Version(string: "0.1.8")))

        XCTAssertEqual(result.dependencies[3].name, "d")
        XCTAssertEqual(result.dependencies[3].url, URL(string: "https://github.com/d/d.git")!)
        XCTAssertEqual(result.dependencies[3].requirement, .revision(revision: "abc"))

        XCTAssertEqual(result.dependencies[4].name, "e")
        XCTAssertEqual(result.dependencies[4].url, URL(string: "https://github.com/e/e.git")!)
        XCTAssertEqual(result.dependencies[4].requirement, .branch(name: "develop"))

        XCTAssertEqual(result.dependencies[5].name, "f")
        XCTAssertEqual(result.dependencies[5].url, URL(string: "https://github.com/f/f.git")!)
        XCTAssertEqual(result.dependencies[5].requirement, .range(lowerBound: try! Version(string: "1.2.3"), upperBound: try! Version(string: "2.0.0")))

        XCTAssertEqual(result.dependencies[6].name, "g")
        XCTAssertEqual(result.dependencies[6].url, URL(string: "https://github.com/g/g.git")!)
        XCTAssertEqual(result.dependencies[6].requirement, .range(lowerBound: try! Version(string: "1.2.3"), upperBound: try! Version(string: "1.2.6")))

        XCTAssertEqual(result.dependencies[7].name, "h")
        XCTAssertEqual(result.dependencies[7].url, URL(string: "https://github.com/h/h.git")!)
        XCTAssertEqual(result.dependencies[7].requirement, .range(lowerBound: try! Version(string: "2.2.3"), upperBound: try! Version(string: "2.2.7")))
    }

    func testPackageDescriptionErrorString() {
        XCTAssertEqual("\(PackageDescriptionError.loadingFailed("abc").localizedDescription)", "Could not get package data, swift package dump-package failed: abc")
        XCTAssertEqual("\(PackageDescriptionError.parsingFailed("abc", "def").localizedDescription)", "Could not parse package data: abc\n\nPackage Data: def")
    }

    func testDependencyRequirementString() {
        XCTAssertEqual("\(DependencyRequirement.exact(version: try! Version(string: "0.1.2")))", "0.1.2")
        XCTAssertEqual("\(DependencyRequirement.revision(revision: "abc"))", "abc")
        XCTAssertEqual("\(DependencyRequirement.branch(name: "def"))", "def")
        XCTAssertEqual("\(DependencyRequirement.range(lowerBound: try! Version(string: "1.0.4"), upperBound: try! Version(string: "1.3.4")))", "1.0.4..<1.3.4")
    }

}
