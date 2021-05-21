enum TestUtils {

    static let emptyPackageResolvedFileContent = """
        {
            "object": {
                "pins": []
            },
            "version": 1
        }
        """

    static let packageResolvedFileContent = """
        {
            "object": {
                "pins": [
                {
                    "package": "a",
                    "repositoryURL": "https://github.com/a/a.git",
                    "state": {
                        "branch": null,
                        "revision": "abc",
                        "version": null
                    }
                },
                {
                    "package": "b",
                    "repositoryURL": "https://github.com/b/b",
                    "state": {
                        "branch": null,
                        "revision": "def",
                        "version": "0.0.0"
                    }
                },
                {
                    "package": "c",
                    "repositoryURL": "https://github.com/c/c.git",
                    "state": {
                        "branch": "main",
                        "revision": "ghi",
                        "version": null
                    }
                }
                ]
            },
            "version": 1
        }
        """

    static let emptyPackageSwiftFileContent = """
        // swift-tools-version:5.2

        import PackageDescription

        let package = Package(
            name: "Name",
            products: [
                .library(
                    name: "Name",
                    targets: ["Name"]
                ),
            ],
            dependencies: [],
            targets: [
                .target(
                    name: "Name",
                    dependencies: []
                ),
            ]
        )
        """

    static let packageSwiftFileContent = """
        // swift-tools-version:5.2

        import PackageDescription

        let package = Package(
            name: "Name",
            products: [
                .library(
                    name: "Name",
                    targets: ["Name"]
                ),
            ],
            dependencies: [
                .package(
                    url: "https://github.com/a/a",
                    .upToNextMinor(from: "0.3.1")
                ),
                .package(
                    url: "https://github.com/b/b.git",
                    .upToNextMajor(from: "2.3.1")
                ),
                .package(
                    url: "https://github.com/c/c.git",
                    .exact("0.1.8")
                ),
                .package(
                    url: "https://github.com/d/d.git",
                    .revision("abc")
                ),
                .package(
                    url: "https://github.com/e/e.git",
                    .branch("develop")
                ),
                .package(
                    url: "https://github.com/f/f.git",
                    from: "1.2.3"
                ),
                .package(
                    url: "https://github.com/g/g.git",
                    "1.2.3"..<"1.2.6"
                ),
                .package(
                    url: "https://github.com/h/h.git",
                    "2.2.3"..."2.2.6"
                ),
            ],
            targets: [
                .target(
                    name: "Name",
                    dependencies: [
                        "a",
                        "b",
                        "c",
                        "d",
                        "e",
                        "f",
                        "g",
                        "h",
                    ]
                ),
            ]
        )
        """

}
