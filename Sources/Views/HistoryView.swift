#if os(macOS)
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var historyStore: HistoryStore

    @State private var searchText: String = ""
    @State private var selectedEntry: HistoryEntry?

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                HStack {
                    TextField("Search history", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Button("Clear All") { historyStore.clear() }
                        .disabled(historyStore.entries.isEmpty)
                }
                List(selection: $selectedEntry) {
                    ForEach(filteredEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.sourceText)
                                .font(.headline)
                                .lineLimit(2)
                            Text(entry.translatedText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            HStack {
                                Text(entry.direction.displayName)
                                Text(entry.model)
                                    .truncationMode(.tail)
                                if let latency = entry.latency {
                                    Text(String(format: "%.2fs", latency))
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .contextMenu {
                            Button("Copy Source") { NSPasteboard.general.setString(entry.sourceText, forType: .string) }
                            Button("Copy Result") { NSPasteboard.general.setString(entry.translatedText, forType: .string) }
                            Button("Delete") { historyStore.delete(entry) }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { filteredEntries[$0] }.forEach(historyStore.delete)
                    }
                }
            }
            .frame(minWidth: 360)

            Divider()

            if let entry = selectedEntry ?? historyStore.entries.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Source")
                        .font(.headline)
                    ScrollView {
                        Text(entry.sourceText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("Translation")
                        .font(.headline)
                    ScrollView {
                        Text(entry.translatedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                }
                .padding()
            } else {
                Text("No history yet")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }

    private var filteredEntries: [HistoryEntry] {
        historyStore.search(query: searchText)
    }
}
#endif
