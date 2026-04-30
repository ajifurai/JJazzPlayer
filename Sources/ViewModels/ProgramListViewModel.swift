import SwiftUI

@MainActor
final class ProgramListViewModel: ObservableObject {
    @Published var programs: [Program] = []
    @Published var isLoading = false
    @Published var error: String?

    func load(showType: ShowType) async {
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
