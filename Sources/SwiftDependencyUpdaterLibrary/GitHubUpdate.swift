import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Rainbow
import ShellOut

class GitHubUpdate {

    private let dependencies: [Dependency]
    private let folder: URL
    private let remoteName: String
    private let baseBranch: String
    private let slug: String

    init(_ dependencies: [Dependency], in folder: URL) throws {
        self.dependencies = dependencies
        self.folder = folder
        (remoteName, baseBranch) = try Self.getGitInfo(in: folder)
        slug = try Self.getSlug(in: folder)
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

    func execute() throws {
        print("Detected slug: \(slug), baseBranch: \(baseBranch) and remote name: \(remoteName)".italic)
        try setupGit()
        try dependencies.forEach {
            let branchName = $0.branchNameForUpdate
            let remoteBranchExist = doesRemoteBranchExist(branchName)
            if remoteBranchExist {
                print("Branch \(branchName) already exists on the remote.".yellow)
                print("All changes in the branch will be overridden".yellow.bold)
            }
            if doesLocalBranchExist(branchName) {
                print("Branch \(branchName) already exists locally.".yellow)
                try removeLocalBranch(name: branchName)
            }
            try createBranch(name: branchName)
            try $0.update(in: folder)
            try commit(message: $0.changeDescription)
            try pushBranch(name: branchName)
            if !remoteBranchExist {
                try createPullRequest(branchName: branchName, title: $0.changeDescription)
            }
            try backToBaseBranch()
        }
    }

    private func setupGit() throws {
        try shellOut(to: "git", arguments: ["config", "--global", "user.name ", "swift-dependency-updater"], at: folder.path)
        try shellOut(to: "git", arguments: ["config", "--global", "user.email", "\\<\\>"], at: folder.path)
    }

    private func doesBranchExist(ref: String) -> Bool {
        do {
            try shellOut(to: "git", arguments: ["show-ref", "--verify", "--quiet", ref], at: folder.path)
            return true
        } catch {
            return false
        }
    }

    private func doesRemoteBranchExist(_ name: String) -> Bool {
        doesBranchExist(ref: "refs/remotes/\(remoteName)/\(name)")
    }

    private func doesLocalBranchExist(_ name: String) -> Bool {
        doesBranchExist(ref: "refs/heads/\(name)")
    }

    private func createPullRequest(branchName: String, title: String) throws {
        let group = DispatchGroup()
        group.enter()

        let parameterArray: [String: Any] = [
            "head": branchName,
            "base": baseBranch,
            "title": title,
            "body": "This Pull Request was automatically created using [swift-dependency-updater](https://github.com/Nef10/swift-dependency-updater). Any changes will be overriden the next time swift-dependency-updater is executed", // swiftlint:disable:this line_length
            "maintainer_can_modify": true
        ]
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(slug)/pulls")!)
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("token \(ProcessInfo.processInfo.environment["TOKEN"]!)", forHTTPHeaderField: "Authorization")
        let parameters = try JSONSerialization.data(withJSONObject: parameterArray, options: [])
        let task = session.uploadTask(with: request, from: parameters) { data, response, error in
            self.handleCreatePullRequestResponse(data: data, response: response, error: error)
            group.leave()
        }
        task.resume()
        group.wait()
    }

    private func handleCreatePullRequestResponse(data: Data?, response: URLResponse?, error: Error?) {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error creating Pull Request: No HTTPURLResponse".red)
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Data: \(dataString)")
            }
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            return
        }
        guard httpResponse.statusCode == 201 else {
            print("Error creating Pull Request: Got status code \(httpResponse.statusCode)".red)
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Data: \(dataString)")
            }
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            return
        }
        print("Created Pull Request".green)
    }

    private func backToBaseBranch() throws {
        try shellOut(to: .gitCheckout(branch: baseBranch), at: folder.path)
    }

    private func commit(message: String) throws {
        try shellOut(to: .gitCommit(message: message, allowingPrompt: false), at: folder.path)
        print("Committed changes".green)
    }

    private func pushBranch(name: String) throws {
        try shellOut(to: "git", arguments: ["push", remoteName, name, "--force"], at: folder.path)
        print("Pushed to remote".green)
    }

    private func removeLocalBranch(name: String) throws {
        try shellOut(to: "git", arguments: ["branch", "-D", name], at: folder.path)
        print("Removed local copy of branch".green)
    }

    private func createBranch(name: String) throws {
        try shellOut(to: "git", arguments: ["checkout", "-b", name], at: folder.path)
        print("Created branch \(name)".green)
    }

}
