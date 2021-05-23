# swift-dependency-updater

[![CI Status](https://github.com/Nef10/swift-dependency-updater/workflows/CI/badge.svg?event=push)](https://github.com/Nef10/swift-dependency-updater/actions?query=workflow%3A%22CI%22) [![License: MIT](https://img.shields.io/github/license/Nef10/swift-dependency-updater)](https://github.com/Nef10/swift-dependency-updater/blob/master/LICENSE) [![Latest version](https://img.shields.io/github/v/release/Nef10/swift-dependency-updater?label=SemVer&sort=semver)](https://github.com/Nef10/swift-dependency-updater/releases) ![platforms supported: linux | macOS](https://img.shields.io/badge/platform-linux%20%7C%20macOS-blue)

The Swift Dependency Updater is a tool to automatically update dependencies of your swift package manager projects. Unlike `swift package update` it also checks if there are updates which require adjustments for the versions specified in the `Package.swift` file.

## Installation

### [Mint](https://github.com/yonaskolb/mint)
```
mint install Nef10/swift-dependency-updater
```

### Swift Package Manager
```
git clone https://github.com/Nef10/swift-dependency-updater.git
$ cd swift-dependency-updater
$ swift run swift-dependency-updater
```

## Usage

### Locally

#### Update dependencies:

`swift-dependency-updater [update] [<folder>] [--keep-requirements]`

#### List all dependencies and possible updates:

`swift-dependency-updater list [<folder>] [--exclude-indirect] [--updates-only]`

#### Help

Run `swift-dependency-updater --help` for a full list of supported commands, and `swift-dependency-updater help <subcommand>` for detailed help on a specific command.

## Limitation

Currently dependencies specified with either `.branch(_ name:)` or `.revision(_ ref:)` are not supported.

## Inspiration

The tool was inspired by [vintage](https://github.com/vinhnx/vintage), [spm-dependencies-checker](https://github.com/sbertix/spm-dependencies-checker), and [swift-package-dependencies-check](https://github.com/MarcoEidinger/swift-package-dependencies-check).
