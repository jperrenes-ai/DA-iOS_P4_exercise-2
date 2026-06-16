import SwiftUI

struct UserListView: View {
    @StateObject private var viewModel = UserListViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isGridView {
                    gridContent
                } else {
                    listContent
                }
            }
            .navigationTitle("Users")
            .toolbar { toolbarContent }
        }
        .task {
            await viewModel.fetchUsers()
        }
    }

    private var listContent: some View {
        List(viewModel.users) { user in
            NavigationLink(destination: UserDetailView(user: user)) {
                UserRowView(user: user)
            }
            .onAppear {
                loadMoreIfNeeded(currentItem: user)
            }
        }
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                ForEach(viewModel.users) { user in
                    NavigationLink(destination: UserDetailView(user: user)) {
                        UserGridItemView(user: user)
                    }
                    .onAppear {
                        loadMoreIfNeeded(currentItem: user)
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            DisplayModePicker(isGridView: $viewModel.isGridView)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                Task { await viewModel.reloadUsers() }
            }) {
                Image(systemName: "arrow.clockwise")
                    .imageScale(.large)
            }
        }
    }

    private func loadMoreIfNeeded(currentItem item: User) {
        guard viewModel.shouldLoadMoreData(currentItem: item) else { return }
        Task { await viewModel.fetchUsers() }
    }
}

struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        UserListView()
    }
}
