import Foundation

@MainActor
final class UserListViewModel: ObservableObject {
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading = false
    @Published var isGridView = false

    private let repository: UserListRepository
    private let pageSize: Int

    init(
        repository: UserListRepository = UserListRepository(),
        pageSize: Int = 20
    ) {
        self.repository = repository
        self.pageSize = pageSize
    }

    func fetchUsers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let newUsers = try await repository.fetchUsers(quantity: pageSize)
            users.append(contentsOf: newUsers)
        } catch {
            print("Error fetching users: \(error.localizedDescription)")
        }
    }

    func reloadUsers() async {
        users.removeAll()
        await fetchUsers()
    }

    func shouldLoadMoreData(currentItem item: User) -> Bool {
        guard let lastItem = users.last else { return false }
        return !isLoading && item.id == lastItem.id
    }
}
