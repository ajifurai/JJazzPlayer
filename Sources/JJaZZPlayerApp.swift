import SwiftUI

@main
struct JJaZZPlayerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ProgramListView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                AudioPlayerService.shared.saveCurrentPosition()
            }
        }
    }
}
