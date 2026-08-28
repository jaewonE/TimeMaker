import Combine
import Foundation
import TimeMakerCore

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var sessions: [TimerSession] = []
    @Published private(set) var labelUsages: [LabelUsage] = []
    @Published private(set) var persistenceError: String?

    private struct StorageFile: Codable {
        var version: Int
        var sessions: [TimerSession]
        var labelUsages: [LabelUsage]
    }

    private let storageURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.homeDirectoryForCurrentUser
        let directory = applicationSupport.appendingPathComponent("TimeMaker", isDirectory: true)
        storageURL = directory.appendingPathComponent("history.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try load()
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    func addSession(_ session: TimerSession) {
        guard !sessions.contains(where: { $0.id == session.id }) else { return }
        sessions.append(session)
        sessions.sort { $0.endedAt > $1.endedAt }
        save()
    }

    func recordLabelUse(_ rawLabel: String, at date: Date = Date()) {
        let label = normalizedDisplayLabel(rawLabel)
        let normalized = normalizedLookupLabel(label)

        if let index = labelUsages.firstIndex(where: { $0.normalizedLabel == normalized }) {
            labelUsages[index].count += 1
            labelUsages[index].lastUsedAt = date
        } else {
            labelUsages.append(LabelUsage(label: label, lastUsedAt: date))
        }
        sortLabelUsages()
        save()
    }

    func suggestions(matching query: String, limit: Int = 6) -> [LabelUsage] {
        LabelSuggestions.matching(query, usages: labelUsages, limit: limit)
    }

    func completedSecondsToday(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return sessions
            .filter { $0.endedAt >= start && $0.endedAt < end }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    private func load() throws {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        let data = try Data(contentsOf: storageURL)
        let file = try decoder.decode(StorageFile.self, from: data)
        sessions = file.sessions.sorted { $0.endedAt > $1.endedAt }
        labelUsages = consolidatedLabelUsages(file.labelUsages)

        if labelUsages.isEmpty, !sessions.isEmpty {
            rebuildLabelUsagesFromSessions()
        }
        sortLabelUsages()

        if labelUsages != file.labelUsages {
            save()
        }
    }

    private func rebuildLabelUsagesFromSessions() {
        var rebuilt: [String: LabelUsage] = [:]
        for session in sessions {
            let label = normalizedDisplayLabel(session.label)
            let normalized = normalizedLookupLabel(label)
            if var existing = rebuilt[normalized] {
                existing.count += 1
                existing.lastUsedAt = max(existing.lastUsedAt, session.startedAt)
                rebuilt[normalized] = existing
            } else {
                rebuilt[normalized] = LabelUsage(label: label, lastUsedAt: session.startedAt)
            }
        }
        labelUsages = Array(rebuilt.values)
    }

    private func save() {
        do {
            let file = StorageFile(version: 1, sessions: sessions, labelUsages: labelUsages)
            let data = try encoder.encode(file)
            try data.write(to: storageURL, options: [.atomic])
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func sortLabelUsages() {
        labelUsages.sort { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.lastUsedAt > rhs.lastUsedAt
        }
    }

    private func consolidatedLabelUsages(_ usages: [LabelUsage]) -> [LabelUsage] {
        var consolidated: [String: LabelUsage] = [:]

        for usage in usages {
            let label = normalizedDisplayLabel(usage.label)
            let normalized = normalizedLookupLabel(label)

            guard var existing = consolidated[normalized] else {
                consolidated[normalized] = LabelUsage(
                    label: label,
                    count: usage.count,
                    lastUsedAt: usage.lastUsedAt
                )
                continue
            }

            let totalCount = existing.count + usage.count
            if usage.lastUsedAt > existing.lastUsedAt {
                existing = LabelUsage(
                    label: label,
                    count: totalCount,
                    lastUsedAt: usage.lastUsedAt
                )
            } else {
                existing.count = totalCount
            }
            consolidated[normalized] = existing
        }

        return Array(consolidated.values)
    }

    private func normalizedDisplayLabel(_ value: String) -> String {
        LabelNormalization.displayLabel(value)
    }

    private func normalizedLookupLabel(_ value: String) -> String {
        LabelNormalization.lookupKey(value)
    }
}
