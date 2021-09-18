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
cd swift-dependency-updater
swift run swift-dependency-updater
```

## Usage

### Locally

#### Update dependencies:

`swift-dependency-updater [update] [<folder>] [--keep-requirements]`

#### List all dependencies and possible updates:

`swift-dependency-updater list [<folder>] [--exclude-indirect] [--updates-only]`

#### Help

Run `swift-dependency-updater --help` for a full list of supported commands, and `swift-dependency-updater help <subcommand>` for detailed help on a specific command.

#### Completion

Thanks to the [swift-argument-parser](https://github.com/apple/swift-argument-parser) you can generate autocompletion scripts via `swift-dependency-updater --generate-completion-script {zsh|bash|fish}`. The exact command for your shell may vary, but for example for zsh with ~/.zfunctions in your fpath you can use:

`swift-dependency-updater --generate-completion-script zsh > ~/.zfunctions/_swift-dependency-updater`

### GitHub

The swift-dependency-updater can automatically create pull requests on GitHub for each outdated dependency by running `swift-dependency-updater github [<folder>] [--keep-requirements]`. This requires that a valid GitHub token is in the `TOKEN` environment variable as well as that git in checked out folder is authenticated (meaning `git push` will run sucessfully).

While this can be ran locally, it is mostly intended to run via GitHub Actions. The only problem is that a push or a pull request created by an action will not trigger action runs itself, meaning that your CI will not run on a PR created by this command by default. There are [certain workarounds](https://github.com/peter-evans/create-pull-request/blob/main/docs/concepts-guidelines.md#workarounds-to-trigger-further-workflow-runs) available. I recommend [creating a GitHub App to create tokens](https://github.com/peter-evans/create-pull-request/blob/main/docs/concepts-guidelines.md#authenticating-with-github-app-generated-tokens) as it provides the best security.

Once this is done, you can create the action by using the following actions file and place it for example under `.github/workflows/swift-dependency-updater.yml` in your repository:

```
name: Swift Dependency Updater

on:
  schedule:
    - cron:  '17 10 * * 5' # Run every Friday at 10:17 UTC
  workflow_dispatch: # Allows to manually trigger the script

permissions: # The workflow does not need specific permissions as we use a different token
  contents: read

jobs:
  test:
    name: Update Swift Dependencies
    runs-on: ubuntu-latest # The action supports macOS-latest as well
    steps:
    - name: Generate token
      id: generate_token
      uses: tibdex/github-app-token@v1.3.0
      with:
        app_id: ${{ secrets.APP_ID }} # These two secrets need to be added
        private_key: ${{ secrets.APP_PRIVATE_KEY }} # to your repository settings
    - name: Checkout code
      uses: actions/checkout@v2
      with:
        path: repo
        fetch-depth: 0 # Fetching the whole repo is required to check if branches already exist
        token: ${{ steps.generate_token.outputs.token }} # Checkout repo pre-configured with right token
    - name: Install Swift
      uses: fwal/setup-swift@v1.7.0
    - name: Checkout swift-dependency-updater
      uses: actions/checkout@v2
      with:
        repository: Nef10/swift-dependency-updater
        path: swift-dependency-updater
        ref: main # specify a version tag or use main to always use the latest code
    - name: Run swift-dependency-updater
      run: cd swift-dependency-updater && swift run swift-dependency-updater github ../repo
      env:
        TOKEN: ${{ steps.generate_token.outputs.token }} # Required to open the Pull Requests
```

## Limitation

Currently dependencies specified with either `.branch(_ name:)` or `.revision(_ ref:)` are not supported.

## Inspiration

The tool was inspired by [vintage](https://github.com/vinhnx/vintage), [spm-dependencies-checker](https://github.com/sbertix/spm-dependencies-checker), and [swift-package-dependencies-check](https://github.com/MarcoEidinger/swift-package-dependencies-check).
