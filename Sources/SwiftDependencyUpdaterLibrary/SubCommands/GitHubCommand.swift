import ArgumentParser
import Foundation

struct GitHubCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "github", abstract: "Updates dependencies and creates a PR for each one")

    @Argument(help: "Path of the swift package") var folder: String = "."
    @ArgumentParser.Flag(help: "Do not change version requirements in the Package.swift file.") private var keepRequirements: Bool = false

    func run() throws {
        let folder = URL(fileURLWithPath: folder)
        guard folder.hasDirectoryPath else {
            print("Folder argument must be a directory.")
            throw ExitCode.failure
        }
        do {
            var dependencies = try Dependency.loadDependencies(from: folder)
            dependencies = dependencies.filter { $0.update != nil && $0.update != .skipped }
            if keepRequirements {
                dependencies = dependencies.filter {
                    if case .withChangingRequirements = $0.update {
                        return false
                    } else {
                        return true
                    }
                }
            }
            if dependencies.isEmpty {
                print("Everything is already up-to-date!".green)
            } else {
                try update(dependencies, in: folder)
            }
        } catch {
            print(error.localizedDescription)
            throw ExitCode.failure
        }
    }

    private func update(_ dependencies: [Dependency], in folder: URL) throws {
        let git = try Git(in: folder)
        let gitHub = GitHub(git: git)

        try dependencies.forEach {
            let branchName = $0.branchNameForUpdate
            let remoteBranchExist = git.doesRemoteBranchExist(branchName)
            if remoteBranchExist {
                print("Branch \(branchName) already exists on the remote.".yellow)
                print("All changes in the branch will be overridden".yellow.bold)
            }
            if git.doesLocalBranchExist(branchName) {
                print("Branch \(branchName) already exists locally.".yellow)
                try git.removeLocalBranch(name: branchName)
            }
            try git.createBranch(name: branchName)
            try $0.update(in: folder)
            try git.commit(message: $0.changeDescription)
            try git.pushBranch(name: branchName)
            if !remoteBranchExist {
                try gitHub.createPullRequest(branchName: branchName, title: $0.changeDescription)
            }
            try git.backToBaseBranch()
        }
    }

}
