import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ShellOut
@testable import SwiftDependencyUpdaterLibrary
import XCTest

class GitHubTests: XCTestCase {

    class MockURLSession: URLSessionProvider {

        private let expectation: XCTestExpectation

        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }

        func myUploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTaskProvider {
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github.v3+json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "token abc")
            XCTAssertEqual(request.url, URL(string: "https://api.github.com/repos/Nef10/swift-dependency-updater/pulls")!)

            // swiftlint:disable force_cast
            let parameters = try! JSONSerialization.jsonObject(with: bodyData!, options: []) as! [String: Any]
            XCTAssertEqual(parameters["head"] as! String, "Branch")
            XCTAssertEqual(parameters["base"] as! String, "main")
            XCTAssertEqual(parameters["title"] as! String, "Title1")
            XCTAssertTrue(parameters["maintainer_can_modify"] as! Bool)
            // swiftlint:enable force_cast

            return MockURLSessionUploadTask {
                completionHandler(nil, nil, nil)
                self.expectation.fulfill()
            }
        }

    }

    class MockURLSessionUploadTask: URLSessionUploadTaskProvider {

        private let closure: () -> Void

        init(closure: @escaping () -> Void) {
            self.closure = closure
        }

        func resume() {
            closure()
        }
    }

    func testCreatePullRequest() {
        let expectation = XCTestExpectation(description: "Call GitHub Pull Request API")

        let folder = emptyFolderURL()
        try! shellOut(to: ShellOutCommand.gitClone(url: URL(string: "https://github.com/Nef10/swift-dependency-updater.git")!, to: folder.path, allowingPrompt: false))
        let git = try! Git(in: folder)

        let session = MockURLSession(expectation: expectation)
        let gitHub = GitHub(git: git, token: "abc", urlSession: session)

        try! gitHub.createPullRequest(branchName: "Branch", title: "Title1")

        wait(for: [expectation], timeout: 1.0)
    }

}
