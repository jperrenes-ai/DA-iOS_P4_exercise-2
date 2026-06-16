import XCTest
@testable import UserList

@MainActor
final class UserListViewModelTests: XCTestCase {

    func testFetchUsersAppendsResults() async {
        // Given
        let repository = UserListRepository(executeDataRequest: makeMockRequest(json: sampleJSON))
        let viewModel = UserListViewModel(repository: repository, pageSize: 2)

        // When
        await viewModel.fetchUsers()

        // Then
        XCTAssertEqual(viewModel.users.count, 2)
        XCTAssertEqual(viewModel.users[0].name.first, "John")
        XCTAssertEqual(viewModel.users[1].name.first, "Jane")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testFetchUsersAccumulatesAcrossCalls() async {
        // Given
        let repository = UserListRepository(executeDataRequest: makeMockRequest(json: sampleJSON))
        let viewModel = UserListViewModel(repository: repository, pageSize: 2)

        // When
        await viewModel.fetchUsers()
        await viewModel.fetchUsers()

        // Then
        XCTAssertEqual(viewModel.users.count, 4)
    }

    func testReloadUsersClearsAndRefetches() async {
        // Given
        let repository = UserListRepository(executeDataRequest: makeMockRequest(json: sampleJSON))
        let viewModel = UserListViewModel(repository: repository, pageSize: 2)
        await viewModel.fetchUsers()
        XCTAssertEqual(viewModel.users.count, 2)

        // When
        await viewModel.reloadUsers()

        // Then
        XCTAssertEqual(viewModel.users.count, 2)
    }

    func testFetchUsersFailureKeepsStateClean() async {
        // Given
        let invalidJSON = "not json".data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let repository = UserListRepository(executeDataRequest: { _ in (invalidJSON, response) })
        let viewModel = UserListViewModel(repository: repository)

        // When
        await viewModel.fetchUsers()

        // Then
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testShouldLoadMoreDataReturnsFalseWhenEmpty() async {
        // Given
        let repository = UserListRepository(executeDataRequest: makeMockRequest(json: sampleJSON))
        let viewModel = UserListViewModel(repository: repository, pageSize: 2)
        let stranger = User(user: .init(
            name: .init(title: "Mr", first: "Ghost", last: "User"),
            dob: .init(date: "2000-01-01", age: 25),
            picture: .init(large: "", medium: "", thumbnail: "")
        ))

        // Then
        XCTAssertFalse(viewModel.shouldLoadMoreData(currentItem: stranger))
    }

    func testShouldLoadMoreDataReturnsTrueForLastItem() async {
        // Given
        let repository = UserListRepository(executeDataRequest: makeMockRequest(json: sampleJSON))
        let viewModel = UserListViewModel(repository: repository, pageSize: 2)
        await viewModel.fetchUsers()

        // When
        let lastUser = viewModel.users.last!

        // Then
        XCTAssertTrue(viewModel.shouldLoadMoreData(currentItem: lastUser))
    }

    func testShouldLoadMoreDataReturnsFalseForNonLastItem() async {
        // Given
        let repository = UserListRepository(executeDataRequest: makeMockRequest(json: sampleJSON))
        let viewModel = UserListViewModel(repository: repository, pageSize: 2)
        await viewModel.fetchUsers()

        // When
        let firstUser = viewModel.users.first!

        // Then
        XCTAssertFalse(viewModel.shouldLoadMoreData(currentItem: firstUser))
    }
}

private extension UserListViewModelTests {
    var sampleJSON: String {
        """
        {
            "results": [
                {
                    "name": { "title": "Mr", "first": "John", "last": "Doe" },
                    "dob": { "date": "1990-01-01", "age": 31 },
                    "picture": {
                        "large": "https://example.com/large.jpg",
                        "medium": "https://example.com/medium.jpg",
                        "thumbnail": "https://example.com/thumbnail.jpg"
                    }
                },
                {
                    "name": { "title": "Ms", "first": "Jane", "last": "Smith" },
                    "dob": { "date": "1995-02-15", "age": 26 },
                    "picture": {
                        "large": "https://example.com/large.jpg",
                        "medium": "https://example.com/medium.jpg",
                        "thumbnail": "https://example.com/thumbnail.jpg"
                    }
                }
            ]
        }
        """
    }

    func makeMockRequest(json: String) -> (URLRequest) async throws -> (Data, URLResponse) {
        return { request in
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }
    }
}
