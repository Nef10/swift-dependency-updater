import ArgumentParser
import Foundation

struct ListCommand: ParsableCommand {

    static var configuration = CommandConfiguration(commandName: "list", abstract: "Lists all dependencies and possible updates")

    @Argument(help: "Path of the swift package")
    var folder: String = "."
    @ArgumentParser.Flag(help: "Do not include indirect dependencies.")
    private var excludeIndirect = false
    @ArgumentParser.Flag(name: .shortAndLong, help: "Do not include dependencies without update.")
     private var updatesOnly = false

    func run() throws {
        let folder = URL(fileURLWithPath: folder)
        guard folder.hasDirectoryPath else {
            print("Folder argument must be a directory.")
            throw ExitCode.failure
        }
        do {
            var dependencies = try Dependency.loadDependencies(from: folder)
            if excludeIndirect {
                dependencies = dependencies.filter { $0.requirement != nil }
            }
            if updatesOnly {
                dependencies = dependencies.filter { $0.update != nil && $0.update != .skipped }
            }
            if dependencies.isEmpty {
                if updatesOnly {
                    print("Everything up-to-date!".green)
                } else {
                    print("No dependencies found.".green)
                }
            } else {
                print(dependencies.map { String(describing: $0) }.joined(separator: "\n\n"))
            }
        } catch {
            print(error.localizedDescription)
            throw ExitCode.failure
        }
    }

}
