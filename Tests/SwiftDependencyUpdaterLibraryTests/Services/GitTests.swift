import ShellOut
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class GitTests: XCTestCase {

    func testGit() {
        let folder = emptyFolderURL()
        try! shellOut(to: ShellOutCommand.gitClone(url: URL(string: "https://github.com/Nef10/swift-dependency-updater.git")!, to: folder.path, allowingPrompt: false))

        let git = try! Git(in: folder)

        XCTAssertEqual(git.remoteName, "origin")
        XCTAssertEqual(git.baseBranch, "main")
        XCTAssertEqual(git.slug, "Nef10/swift-dependency-updater")

        XCTAssertEqual(try! shellOut(to: "git", arguments: ["config", "--local", "--get", "user.name"], at: folder.path), "swift-dependency-updater")
        XCTAssertEqual(try! shellOut(to: "git", arguments: ["config", "--local", "--get", "user.email"], at: folder.path), "<>")

        XCTAssertTrue(git.doesLocalBranchExist("main"))
        XCTAssertFalse(git.doesLocalBranchExist("test-local-branch"))

        XCTAssertTrue(git.doesRemoteBranchExist("main"))
        XCTAssertFalse(git.doesRemoteBranchExist("branchThatHopefullyDoesNotExist"))

        try! git.createBranch(name: "test-local-branch")
        XCTAssertTrue(git.doesLocalBranchExist("test-local-branch"))

        try! shellOut(to: .gitCheckout(branch: "main"), at: folder.path)
        try! git.removeLocalBranch(name: "test-local-branch")
        XCTAssertFalse(git.doesLocalBranchExist("test-local-branch"))

        try! shellOut(to: .createFile(named: "abc", contents: "content"), at: folder.path)
        try! git.commit(message: "Test message")
        XCTAssertEqual(try! shellOut(to: "git", arguments: ["log", "-1", "--pretty=%B"], at: folder.path).trimmingCharacters(in: .whitespacesAndNewlines), "Test message")
    }

}
