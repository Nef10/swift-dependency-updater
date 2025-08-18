import Rainbow
import Releases
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class SwiftPackageTests: XCTestCase {

    func testEmptyFolder() {
        let folder = emptyFolderURL()
        let swiftPackage = SwiftPackage(in: folder)
        let update = Update.withChangingRequirements(try! Version(string: "2.1.2"))
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
        let dependency = Dependency(name: "ABC", url: URL(string: "https://github.com/Name/abc.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)
        #if os(Linux)
        assert(
            try swiftPackage.performUpdate(update, of: dependency),
            throws: SwiftPackageError.readFailed("The operation could not be completed. The file doesn’t exist.")
        )
        #else
        assert(
            try swiftPackage.performUpdate(update, of: dependency),
            throws: SwiftPackageError.readFailed("The file “Package.swift” couldn’t be opened because there is no such file.")
        )
        #endif
    }

    func testInvalidFile() {
        let folder = emptyFolderURL()
        let file = temporaryFileURL(in: folder, name: "Package.swift")
        createFile(at: file, content: "\n")
        let swiftPackage = SwiftPackage(in: folder)
        let update = Update.withChangingRequirements(try! Version(string: "2.1.2"))
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
        let dependency = Dependency(name: "ABC", url: URL(string: "https://github.com/Name/abc.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)
        assert(
            try swiftPackage.performUpdate(update, of: dependency),
            throws: SwiftPackageError.resultCountMismatch(dependency.name, 0)
        )
    }

    func testInvalidUpdate() {
        let folder = emptyFolderURL()
        let swiftPackage = SwiftPackage(in: folder)
        let update = Update.withoutChangingRequirements(try! Version(string: "1.2.4"))
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
        let dependency = Dependency(name: "ABC", url: URL(string: "https://github.com/Name/abc.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)
        assert(
            try swiftPackage.performUpdate(update, of: dependency),
            throws: SwiftPackageError.invalidUpdate(dependency.name, update)
        )

    }

    func testUpdateUpToNextMinor() {
        let (swiftPackage, file) = setUpSamplePackage()
        let update = Update.withChangingRequirements(try! Version(string: "1.2.3"))
        let resolvedVersion = TestUtils.resolvedVersion("0.3.3")
        let dependency = Dependency(name: "a", url: URL(string: "https://github.com/a/a")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)

        XCTAssertFalse(try swiftPackage.performUpdate(update, of: dependency))

        XCTAssert(try! String(contentsOf: file, encoding: .utf8).contains("""
                .package(
                    url: "https://github.com/a/a",
                    .upToNextMinor(from: "1.2.3")
                ),
        """))
    }

    func testUpdateUpToNextMajor() {
        let (swiftPackage, file) = setUpSamplePackage()
        let update = Update.withChangingRequirements(try! Version(string: "3.0.3"))
        let resolvedVersion = TestUtils.resolvedVersion("2.5.3")
        let dependency = Dependency(name: "b", url: URL(string: "https://github.com/b/b.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)

        XCTAssertFalse(try swiftPackage.performUpdate(update, of: dependency))

        XCTAssert(try! String(contentsOf: file, encoding: .utf8).contains("""
                .package(
                    url: "https://github.com/b/b.git",
                    .upToNextMajor(from: "3.0.3")
                ),
        """))
    }

    func testUpdateExact() {
        let (swiftPackage, file) = setUpSamplePackage()
        let update = Update.withChangingRequirements(try! Version(string: "0.1.9"))
        let resolvedVersion = TestUtils.resolvedVersion("0.1.8")
        let dependency = Dependency(name: "c", url: URL(string: "https://github.com/c/c.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)

        XCTAssertFalse(try swiftPackage.performUpdate(update, of: dependency))

        XCTAssert(try! String(contentsOf: file, encoding: .utf8).contains("""
                .package(
                    url: "https://github.com/c/c.git",
                    .exact("0.1.9")
                ),
        """))
    }

    func testUpdateFrom() {
        let (swiftPackage, file) = setUpSamplePackage()
        let update = Update.withChangingRequirements(try! Version(string: "2.1.9"))
        let resolvedVersion = TestUtils.resolvedVersion("1.3.8")
        let dependency = Dependency(name: "f", url: URL(string: "https://github.com/f/f.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)

        XCTAssertFalse(try swiftPackage.performUpdate(update, of: dependency))

        XCTAssert(try! String(contentsOf: file, encoding: .utf8).contains("""
                .package(
                    url: "https://github.com/f/f.git",
                    from: "2.1.9"
                ),
        """))
    }

    func testUpdateRange() {
        let (swiftPackage, file) = setUpSamplePackage()
        let update = Update.withChangingRequirements(try! Version(string: "1.2.6"))
        let resolvedVersion = TestUtils.resolvedVersion("1.2.5")
        let dependency = Dependency(name: "g", url: URL(string: "https://github.com/g/g.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)

        XCTAssertTrue(try swiftPackage.performUpdate(update, of: dependency))

        XCTAssert(try! String(contentsOf: file, encoding: .utf8).contains("""
                .package(
                    url: "https://github.com/g/g.git",
                    "1.2.3"..<"1.2.7"
                ),
        """))
    }

    func testUpdateClosedRange() {
        let (swiftPackage, file) = setUpSamplePackage()
        let update = Update.withChangingRequirements(try! Version(string: "3.1.1"))
        let resolvedVersion = TestUtils.resolvedVersion("2.2.6")
        let dependency = Dependency(name: "h", url: URL(string: "https://github.com/h/h.git")!, requirement: nil, resolvedVersion: resolvedVersion, update: update)

        XCTAssertTrue(try swiftPackage.performUpdate(update, of: dependency))

        XCTAssert(try! String(contentsOf: file, encoding: .utf8).contains("""
                .package(
                    url: "https://github.com/h/h.git",
                    "2.2.3"..."3.1.1"
                ),
        """))
    }

    func testSwiftPackageErrorString() {
        let originalValue = Rainbow.enabled
        Rainbow.enabled = false

        XCTAssertEqual(
            "\(SwiftPackageError.invalidUpdate("abc", Update.withoutChangingRequirements(try! Version(string: "0.1.2"))).localizedDescription)",
            "Invalid update for abc: 0.1.2 (Without changing requirements)"
        )
        XCTAssertEqual(
            "\(SwiftPackageError.resultCountMismatch("abc", 2).localizedDescription)",
            "Finding version requirement in Package.swift failed for abc: Got 2 instead of 1 result"
        )
        XCTAssertEqual(
            "\(SwiftPackageError.noResultMatch("name", ["", "abc", nil]).localizedDescription)",
            "Finding version requirement in Package.swift failed for name. Findings: \(["", "abc", nil])"
        )
        XCTAssertEqual( "\(SwiftPackageError.readFailed("err").localizedDescription)", "Failed to read Package.swift file: err")
        XCTAssertEqual( "\(SwiftPackageError.writeFailed("err").localizedDescription)", "Failed to write Package.swift file: err")

        Rainbow.enabled = originalValue
    }

    private func setUpSamplePackage() -> (SwiftPackage, URL) {
        let folder = emptyFolderURL()
        let file = temporaryFileURL(in: folder, name: "Package.swift")
        createFile(at: file, content: TestUtils.packageSwiftFileContent)
        return (SwiftPackage(in: folder), file)
    }

}
