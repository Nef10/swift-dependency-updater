import Releases
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class PackageDescriptionTest: XCTestCase {

    func testEmptyFolder() {
        let folder = emptyFolderURL()
        assert(
            try PackageDescription.loadPackageDescription(from: folder),
            throws: PackageDescriptionError.loadingFailed("error: root manifest not found")
        )
    }

    func testInvalidFile() {
        let folder = emptyFolderURL()
        let file = temporaryFileURL(in: folder, name: "Package.swift")
        createFile(at: file, content: "// swift-tools-version:5.4.0\n")
        #if os(Linux)
        assert(
            try PackageDescription.loadPackageDescription(from: folder),
            throws: PackageDescriptionError.loadingFailed("\(folder.path): error: malformed")
        )
        #else
        assert(
            try PackageDescription.loadPackageDescription(from: folder),
            throws: PackageDescriptionError.loadingFailed("/private\(folder.path): error: malformed")
        )
        #endif
    }

     func testParsing() {
        let folder = emptyFolderURL()
        let file = temporaryFileURL(in: folder, name: "Package.swift")
        createFile(at: file, content: TestUtils.packageSwiftFileContent)
        let result = try! PackageDescription.loadPackageDescription(from: folder)
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

}
