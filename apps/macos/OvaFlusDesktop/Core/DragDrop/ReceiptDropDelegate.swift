import SwiftUI
import UniformTypeIdentifiers

struct ReceiptDropDelegate: DropDelegate {
    @Binding var receiptURL: URL?
    @Binding var isTargeted: Bool

    private let allowedTypes: [UTType] = [.image, .pdf, .png, .jpeg, .heic]

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.fileURL])
    }

    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func performDrop(info: DropInfo) -> Bool {
        isTargeted = false

        guard let provider = info.itemProviders(for: [.fileURL]).first else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            // Validate file type
            guard let type = UTType(filenameExtension: url.pathExtension),
                  self.allowedTypes.contains(where: { type.conforms(to: $0) }) else {
                return
            }

            DispatchQueue.main.async {
                self.receiptURL = url
            }
        }

        return true
    }
}
