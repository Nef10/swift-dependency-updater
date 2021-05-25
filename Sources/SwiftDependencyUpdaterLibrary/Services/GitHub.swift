import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Rainbow

class GitHub {

    private let git: Git

    init(git: Git) {
        self.git = git
    }

    func createPullRequest(branchName: String, title: String) throws {
        let group = DispatchGroup()
        group.enter()

        let parameterArray: [String: Any] = [
            "head": branchName,
            "base": git.baseBranch,
            "title": title,
            "body": "This Pull Request was automatically created using [swift-dependency-updater](https://github.com/Nef10/swift-dependency-updater). Any changes will be overriden the next time swift-dependency-updater is executed", // swiftlint:disable:this line_length
            "maintainer_can_modify": true
        ]
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(git.slug)/pulls")!)
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

}
