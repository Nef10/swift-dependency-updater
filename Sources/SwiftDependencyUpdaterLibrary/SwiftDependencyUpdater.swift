import ArgumentParser

public struct SwiftDependencyUpdater: ParsableCommand {

    public static var configuration = CommandConfiguration(
        commandName: "swift-dependency-updater",
        abstract: "A CLI tool to update Swift Pacakge Manager dependencies",
        version: "0.0.2",
        subcommands: [List.self, UpdateCommand.self, GitHub.self],
        defaultSubcommand: UpdateCommand.self

    )

    public init() {
    }

}
