enum TestUtils {

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

}
