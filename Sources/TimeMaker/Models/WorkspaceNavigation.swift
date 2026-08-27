import Combine
import Foundation

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case analytics
    case settings

    var id: String { rawValue }
}

@MainActor
final class WorkspaceNavigation: ObservableObject {
    @Published var selection: WorkspaceSection = .analytics
}
