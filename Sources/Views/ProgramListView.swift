import SwiftUI

struct ProgramListView: View {
    @ObservedObject private var settings = PlayerSettings.shared
    @StateObject private var viewModel = ProgramListViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            programList
                .toolbar {
                    ToolbarItem(placement: .principal) { showTypePicker }
                    ToolbarItem(placement: .primaryAction) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) { SettingsView() }
        }
        .task { await viewModel.load(showType: settings.selectedShowType) }
        .onChange(of: settings.selectedShowType) { _, newType in
            Task { await viewModel.load(showType: newType) }
        }
    }

    private var showTypePicker: some View {
        Picker("", selection: $settings.selectedShowType) {
            Text("pick-up").tag(ShowType.pickup)
            Text("夜ジャズ").tag(ShowType.yorujazz)
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
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
            if let err = viewModel.error { Text(err).foregroundStyle(.red).padding() }
        }
    }
}
