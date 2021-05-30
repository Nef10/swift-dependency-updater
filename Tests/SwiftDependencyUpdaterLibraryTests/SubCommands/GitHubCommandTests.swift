@testable import SwiftDependencyUpdaterLibrary
import XCTest

class MockGitHub: GitHubProvider {

    private let expectation: XCTestExpectation?
    private let expectedBranchName: String
    private let expectedTitle: String

    init(expectation: XCTestExpectation, branchName: String, title: String) {
        self.expectation = expectation
        self.expectedBranchName = branchName
        self.expectedTitle = title
    }

    required init(git: GitProvider, token: String, urlSession: URLSessionProvider) { // swiftlint:disable:this unavailable_function
        fatalError("Do not call this initializer")
    }

    func createPullRequest(branchName: String, title: String) throws {
        XCTAssertEqual(branchName, expectedBranchName)
        XCTAssertEqual(title, expectedTitle)
        expectation?.fulfill()
    }

}

class MockGit: GitProvider {

    let remoteName: String
    let baseBranch: String
    let slug: String

    let backToBaseBranchExpectation = XCTestExpectation(description: "Call backToBaseBranch")
    let commitExpectation = XCTestExpectation(description: "Call commit")
    let pushBranchExpectation = XCTestExpectation(description: "Call pushBranch")
    let removeLocalBranchExpectation = XCTestExpectation(description: "Call removeLocalBranch")
    let createBranchExpectation = XCTestExpectation(description: "Call createBranch")

    var expectedCommitMessage: String?
    var expectedBranchName: String?

    var doesRemoteBranchExist = false
    var doesLocalBranchExist = false

    init() {
        remoteName = "origin"
        baseBranch = "main"
        slug = "A/B"
    }

    required init(in folder: URL) throws { // swiftlint:disable:this unavailable_function
        fatalError("Do not call this initializer")
    }

    func backToBaseBranch() throws {
        backToBaseBranchExpectation.fulfill()
    }

    func commit(message: String) throws {
        if let expectedCommitMessage = expectedCommitMessage {
            XCTAssertEqual(expectedCommitMessage, message)
        }
        commitExpectation.fulfill()
    }

    func pushBranch(name: String) throws {
        if let expectedBranchName = expectedBranchName {
            XCTAssertEqual(expectedBranchName, name)
        }
        pushBranchExpectation.fulfill()
    }

    func removeLocalBranch(name: String) throws {
        if let expectedBranchName = expectedBranchName {
            XCTAssertEqual(expectedBranchName, name)
        }
        removeLocalBranchExpectation.fulfill()
    }

    func createBranch(name: String) throws {
        if let expectedBranchName = expectedBranchName {
            XCTAssertEqual(expectedBranchName, name)
        }
        createBranchExpectation.fulfill()
    }

    func doesRemoteBranchExist(_ name: String) -> Bool {
        doesRemoteBranchExist
    }

    func doesLocalBranchExist(_ name: String) -> Bool {
        doesLocalBranchExist
    }

}

class GitHubCommandTests: XCTestCase {

    func testFileInsteadOfFolder() {
        let url = emptyFileURL()
        let result = outputFromExecutionWith(arguments: ["github", url.path])
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssertEqual(result.output, "Folder argument must be a directory.")
    }

    func testEmptyFolder() {
        let url = emptyFolderURL()
        let result = outputFromExecutionWith(arguments: ["github", url.path])
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
        let result = outputFromExecutionWith(arguments: ["github", folder.path])
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssert(result.output.contains("Could not get package data, swift package dump-package failed"))
    }

    func testNoDependencies() {
        let folder = createEmptySwiftPackage()
        let result = outputFromExecutionWith(arguments: ["github", folder.path])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssertEqual(result.output, "Everything is already up-to-date!")
    }

    func testNoDependenciesKeepRequirements() {
        let folder = createEmptySwiftPackage()
        let result = outputFromExecutionWith(arguments: ["github", folder.path, "--keep-requirements"])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.errorOutput, "")
        XCTAssertEqual(result.output, "Everything is already up-to-date!")
    }

    func testUpdateNoDependencies() {
        let gitHubPRExpectation = XCTestExpectation(description: "Call GitHub Create Pull Request")

        let folder = emptyFolderURL()
        let gitHub = MockGitHub(expectation: gitHubPRExpectation, branchName: "", title: "")
        let git = MockGit()
        let dependencies = [Dependency]()

        gitHubPRExpectation.isInverted = true
        git.backToBaseBranchExpectation.isInverted = true
        git.commitExpectation.isInverted = true
        git.pushBranchExpectation.isInverted = true
        git.removeLocalBranchExpectation.isInverted = true
        git.createBranchExpectation.isInverted = true

        try! GitHubCommand.update(dependencies, in: folder, git: git, gitHub: gitHub)

        wait(for:
                [
                    git.removeLocalBranchExpectation,
                    git.createBranchExpectation,
                    git.commitExpectation,
                    git.pushBranchExpectation,
                    gitHubPRExpectation,
                    git.backToBaseBranchExpectation,
                ],
            timeout: 1.0,
            enforceOrder: true)
    }

    func testUpdateNoBranchExists() {
        let gitHubPRExpectation = XCTestExpectation(description: "Call GitHub Create Pull Request")

        let folder = emptyFolderURL()
        let gitHub = MockGitHub(expectation: gitHubPRExpectation, branchName: "swift-dependency-updater/depname", title: "")
        let git = MockGit()
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
        let url = URL(string: "https://github.com/Name/abc.git")!
        let dependency = Dependency(name: "depNAme", url: url, requirement: nil, resolvedVersion: resolvedVersion, update: nil)
        let dependencies = [dependency]

        git.removeLocalBranchExpectation.isInverted = true

        git.expectedCommitMessage = ""
        git.expectedBranchName = "swift-dependency-updater/depname"

        try! GitHubCommand.update(dependencies, in: folder, git: git, gitHub: gitHub)

        wait(for:
                [
                    git.removeLocalBranchExpectation,
                    git.createBranchExpectation,
                    git.commitExpectation,
                    git.pushBranchExpectation,
                    gitHubPRExpectation,
                    git.backToBaseBranchExpectation,
                ],
            timeout: 1.0,
            enforceOrder: true)
    }

    func testUpdateLocalBranchExists() {
        let gitHubPRExpectation = XCTestExpectation(description: "Call GitHub Create Pull Request")

        let folder = emptyFolderURL()
        let gitHub = MockGitHub(expectation: gitHubPRExpectation, branchName: "swift-dependency-updater/depname", title: "")
        let git = MockGit()
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
        let url = URL(string: "https://github.com/Name/abc.git")!
        let dependency = Dependency(name: "depNAme", url: url, requirement: nil, resolvedVersion: resolvedVersion, update: nil)
        let dependencies = [dependency]

        git.doesLocalBranchExist = true

        git.expectedCommitMessage = ""
        git.expectedBranchName = "swift-dependency-updater/depname"

        try! GitHubCommand.update(dependencies, in: folder, git: git, gitHub: gitHub)

        wait(for:
                [
                    git.removeLocalBranchExpectation,
                    git.createBranchExpectation,
                    git.commitExpectation,
                    git.pushBranchExpectation,
                    gitHubPRExpectation,
                    git.backToBaseBranchExpectation,
                ],
            timeout: 1.0,
            enforceOrder: true)
    }

    func testUpdateRemoteBranchExists() {
        let gitHubPRExpectation = XCTestExpectation(description: "Call GitHub Create Pull Request")

        let folder = emptyFolderURL()
        let gitHub = MockGitHub(expectation: gitHubPRExpectation, branchName: "swift-dependency-updater/depname", title: "")
        let git = MockGit()
        let resolvedVersion = TestUtils.resolvedVersion("1.2.3")
        let url = URL(string: "https://github.com/Name/abc.git")!
        let dependency = Dependency(name: "depNAme", url: url, requirement: nil, resolvedVersion: resolvedVersion, update: nil)
        let dependencies = [dependency]

        git.doesRemoteBranchExist = true
        git.removeLocalBranchExpectation.isInverted = true
        gitHubPRExpectation.isInverted = true

        git.expectedCommitMessage = ""
        git.expectedBranchName = "swift-dependency-updater/depname"

        try! GitHubCommand.update(dependencies, in: folder, git: git, gitHub: gitHub)

        wait(for:
                [
                    git.removeLocalBranchExpectation,
                    git.createBranchExpectation,
                    git.commitExpectation,
                    git.pushBranchExpectation,
                    gitHubPRExpectation,
                    git.backToBaseBranchExpectation,
                ],
            timeout: 1.0,
            enforceOrder: true)
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
