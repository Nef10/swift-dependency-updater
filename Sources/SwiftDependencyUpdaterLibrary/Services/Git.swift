import Foundation
import Rainbow
import ShellOut

protocol GitProvider {
    var remoteName: String { get }
    var baseBranch: String { get }
    var slug: String { get }

    init(in folder: URL) throws
    func backToBaseBranch() throws
    func commit(message: String) throws
    func pushBranch(name: String) throws
    func removeLocalBranch(name: String) throws
    func createBranch(name: String) throws
    func doesRemoteBranchExist(_ name: String) -> Bool
    func doesLocalBranchExist(_ name: String) -> Bool
}

class Git: GitProvider {

    private let folder: URL

    let remoteName: String
    let baseBranch: String
    let slug: String

    required init(in folder: URL) throws {
        self.folder = folder
        (remoteName, baseBranch) = try Self.getGitInfo(in: folder)
        slug = try Self.getSlug(in: folder)
        print("Detected slug: \(slug), baseBranch: \(baseBranch) and remote name: \(remoteName)".italic)
        try setupGit()
    }

    private static func getGitInfo(in folder: URL) throws -> (String, String) {
        let currentBranchName = try shellOut(to: "git", arguments: ["rev-parse", "--abbrev-ref", "HEAD"], at: folder.path)
        let remoteName = try shellOut(to: "git", arguments: ["config", "branch.\(currentBranchName).remote"], at: folder.path)
        return (remoteName, currentBranchName)
    }

    private static func getSlug(in folder: URL) throws -> String {
        let prefixes = ["git@github.com:", "https://github.com/"]
        let suffix = ".git"
        var remoteURL = try shellOut(to: "git", arguments: ["config", "--get", "remote.origin.url"], at: folder.path)
        for prefix in prefixes {
            if remoteURL.hasPrefix(prefix) {
                remoteURL = String(remoteURL.dropFirst(prefix.count))
            }
        }
        if remoteURL.hasSuffix(suffix) {
            remoteURL = String(remoteURL.dropLast(suffix.count))
        }
        return remoteURL
    }

    private func setupGit() throws {
        try shellOut(to: "git", arguments: ["config", "--local", "user.name ", "swift-dependency-updater"], at: folder.path)
        try shellOut(to: "git", arguments: ["config", "--local", "user.email", "\\<\\>"], at: folder.path)
    }

    func backToBaseBranch() throws {
        try shellOut(to: .gitCheckout(branch: baseBranch), at: folder.path)
    }

    func commit(message: String) throws {
        try shellOut(to: .gitCommit(message: message, allowingPrompt: false), at: folder.path)
        print("Committed changes".green)
    }

    func pushBranch(name: String) throws {
        try shellOut(to: "git", arguments: ["push", remoteName, name, "--force"], at: folder.path)
        print("Pushed to remote".green)
    }

    func removeLocalBranch(name: String) throws {
        try shellOut(to: "git", arguments: ["branch", "-D", name], at: folder.path)
        print("Removed local copy of branch".green)
    }

    func createBranch(name: String) throws {
        try shellOut(to: "git", arguments: ["checkout", "-b", name], at: folder.path)
        print("Created branch \(name)".green)
    }

    func doesRemoteBranchExist(_ name: String) -> Bool {
        doesBranchExist(ref: "refs/remotes/\(remoteName)/\(name)")
    }

    func doesLocalBranchExist(_ name: String) -> Bool {
        doesBranchExist(ref: "refs/heads/\(name)")
    }

    private func doesBranchExist(ref: String) -> Bool {
        do {
            try shellOut(to: "git", arguments: ["show-ref", "--verify", "--quiet", ref], at: folder.path)
            return true
        } catch {
            return false
        }
    }

}
