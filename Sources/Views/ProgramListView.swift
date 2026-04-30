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
        let visible = viewModel.programs.filter { !settings.hiddenPrograms.contains($0.id) }
        return List(visible) { program in
            NavigationLink(destination: ProgramDetailView(program: program)) {
                ProgramRowView(program: program)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                markButtons(for: program)
            }
            .swipeActions(edge: .trailing) {
                hideButton(for: program)
            }
        }
        .safeAreaInset(edge: .bottom) { PlayerControlsView() }
        .overlay {
            if viewModel.isLoading { ProgressView() }
            if let err = viewModel.error { Text(err).foregroundStyle(.red).padding() }
        }
    }

    private func markButtons(for program: Program) -> some View {
        let current = settings.programMarks[program.id]
        return Group {
            Button { settings.toggleMark(.star, for: program.id) } label: {
                Label(ProgramMark.star.label,
                      systemImage: current == .star ? "star.slash.fill" : "star.fill")
            }.tint(.yellow)
            Button { settings.toggleMark(.bookmark, for: program.id) } label: {
                Label(ProgramMark.bookmark.label,
                      systemImage: current == .bookmark ? "bookmark.slash.fill" : "bookmark.fill")
            }.tint(.blue)
        }
    }

    private func hideButton(for program: Program) -> some View {
        Button(role: .destructive) { settings.hide(program.id) } label: {
            Label("非表示", systemImage: "eye.slash.fill")
        }
    }
}
