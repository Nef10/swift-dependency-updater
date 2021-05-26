import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Rainbow

protocol URLSessionProvider {
    func myUploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTaskProvider
}

protocol URLSessionUploadTaskProvider {
    func resume()
}

class GitHub {

    private let git: Git
    private let token: String
    private let session: URLSessionProvider

    init(git: Git, token: String = ProcessInfo.processInfo.environment["TOKEN"]!, urlSession session: URLSessionProvider = URLSession.shared) {
        self.git = git
        self.token = token
        self.session = session
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
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        let parameters = try JSONSerialization.data(withJSONObject: parameterArray, options: [])
        let task = session.myUploadTask(with: request, from: parameters) { data, response, error in
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

extension URLSession: URLSessionProvider {
    func myUploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTaskProvider {
        uploadTask(with: request, from: bodyData, completionHandler: completionHandler)
    }
}

extension URLSessionUploadTask: URLSessionUploadTaskProvider {
}
