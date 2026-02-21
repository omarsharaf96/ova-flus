import SwiftUI
import LinkKit

/// UIViewControllerRepresentable wrapper around Plaid LinkKit.
/// Requires the LinkKit SPM package: https://github.com/plaid/plaid-link-ios-spm
struct PlaidLinkView: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String, SuccessMetadata) -> Void
    let onExit: (ExitMetadata?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        var configuration = LinkTokenConfiguration(token: linkToken) { success in
            onSuccess(success.publicToken, success.metadata)
        }

        configuration.onExit = { exit in
            onExit(exit.metadata)
        }

        let result = Plaid.create(configuration)
        switch result {
        case .failure:
            let vc = UIViewController()
            DispatchQueue.main.async { onExit(nil) }
            return vc
        case .success(let handler):
            context.coordinator.handler = handler
            let vc = UIViewController()
            handler.open(presentUsing: .viewController(vc))
            return vc
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var handler: (any Handler)?
    }
}
