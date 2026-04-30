import SwiftUI

struct ProgramListView: View {
    let showType: ShowType
    @StateObject private var viewModel: ProgramListViewModel

    init(showType: ShowType) {
        self.showType = showType
        _viewModel = StateObject(wrappedValue: ProgramListViewModel(showType: showType))
    }

    var body: some View {
        NavigationStack {
            programList
                .navigationTitle(showType == .pickup ? "JJazz pick-up" : "夜ジャズ")
        }
        .task { await viewModel.load() }
    }

    private var programList: some View {
        List(viewModel.programs) { program in
            NavigationLink(destination: ProgramDetailView(program: program)) {
                ProgramRowView(program: program)
            }
        }
        .safeAreaInset(edge: .bottom) { PlayerControlsView() }
        .overlay {
            if viewModel.isLoading { ProgressView() }
            if let err = viewModel.error {
                Text(err).foregroundStyle(.red).padding()
            }
        }
    }
}
