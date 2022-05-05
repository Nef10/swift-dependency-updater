import ArgumentParser
import Foundation

struct GitHubCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "github", abstract: "Updates dependencies and creates a PR for each one")

    @Argument(help: "Path of the swift package") var folder: String = "."
    @ArgumentParser.Flag(help: "Do not change version requirements in the Package.swift file.") private var keepRequirements = false

    static func update(_ dependencies: [Dependency], in folder: URL, git: GitProvider? = nil, gitHub: GitHubProvider? = nil) throws {
        let git = try git ?? Git(in: folder)
        let gitHub = gitHub ?? GitHub(git: git)

        try dependencies.forEach {
            let branchName = $0.branchNameForUpdate
            let remoteBranchExist = git.doesRemoteBranchExist(branchName)
            if remoteBranchExist {
                print("All changes in the branch will be overridden".yellow.bold)
            }
            if git.doesLocalBranchExist(branchName) {
                try git.removeLocalBranch(name: branchName)
            }
            try git.createBranch(name: branchName)
            do {
                try $0.update(in: folder)
                try git.commit(message: $0.changeDescription)
                try git.pushBranch(name: branchName)
                if !remoteBranchExist {
                    try gitHub.createPullRequest(branchName: branchName, title: $0.changeDescription)
                }
                try git.backToBaseBranch()
            } catch let SwiftPackageError.resultCountMismatch(name, count) where count == 0 { // false positive, count is an integer swiftlint:disable:this empty_count
                print("Warning: Could not find version requirement for \(name) in Package.swift - " +
                      "this could be due to the dependency only beeing required on a specific platform.".yellow)
            } catch {
                throw error
            }
        }
    }

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
                try Self.update(dependencies, in: folder)
            }
        } catch {
            print(error.localizedDescription)
            throw ExitCode.failure
        }
    }

}
