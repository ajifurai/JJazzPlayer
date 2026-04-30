import SwiftUI

@MainActor
final class ProgramListViewModel: ObservableObject {
    let showType: ShowType
    @Published var programs: [Program] = []
    @Published var isLoading = false
    @Published var error: String?

    init(showType: ShowType) { self.showType = showType }

    func load() async {
        isLoading = true
        error = nil
        do {
            programs = try await showType == .pickup
                ? JJazzScraper.fetchPickupPrograms()
                : JJazzScraper.fetchYorujazzPrograms()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
