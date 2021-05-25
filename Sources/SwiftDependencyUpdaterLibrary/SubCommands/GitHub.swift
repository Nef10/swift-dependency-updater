import ArgumentParser
import Foundation

struct GitHub: ParsableCommand {

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
                let gitHubUpdate = try GitHubUpdate(dependencies, in: folder)
                try gitHubUpdate.execute()
            }
        } catch {
            print(error.localizedDescription)
            throw ExitCode.failure
        }
    }

}
