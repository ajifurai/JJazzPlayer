import SwiftUI

@main
struct JJaZZPlayerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TabView {
                ProgramListView(showType: .pickup)
                    .tabItem { Label("pick-up", systemImage: "music.note.list") }
                ProgramListView(showType: .yorujazz)
                    .tabItem { Label("夜ジャズ", systemImage: "moon.fill") }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                AudioPlayerService.shared.saveCurrentPosition()
            }
        }
    }
}
