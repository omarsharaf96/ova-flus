import SwiftUI

struct AddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var merchant = ""
    @State private var amount = ""
    @State private var category = "Uncategorized"
    @State private var date = Date()
    @State private var notes = ""
    @State private var receiptURL: URL?
    @State private var isTargeted = false

    let categories = [
        "Uncategorized", "Food & Dining", "Shopping", "Transportation",
        "Bills & Utilities", "Entertainment", "Health", "Travel", "Other"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text("New Transaction")
                    .font(.headline)
                Spacer()
                Button("Save") { saveTransaction() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(merchant.isEmpty || amount.isEmpty)
            }
            .padding()

            Divider()

            Form {
                TextField("Merchant", text: $merchant)
                TextField("Amount", text: $amount)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3)

                // Receipt drop zone
                GroupBox("Receipt") {
                    if let url = receiptURL {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(url.lastPathComponent)
                            Spacer()
                            Button(role: .destructive) {
                                receiptURL = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text("Drop receipt image or PDF here")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Browse...") { openFilePicker() }
                                .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .foregroundStyle(.secondary)
                        )
                        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                            handleDrop(providers: providers)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 450, height: 520)
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .pdf]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            receiptURL = panel.url
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
            if let data = data as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    self.receiptURL = url
                }
            }
        }
        return true
    }

    private func saveTransaction() {
        // TODO: Save transaction via API
        dismiss()
    }
}
