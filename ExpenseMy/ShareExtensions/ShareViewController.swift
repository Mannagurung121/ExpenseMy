//
//  ShareViewController.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        extractSMSText()
    }

    // Step 1: Pull the shared text out of the extension context
    private func extractSMSText() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let providers = item.attachments else {
            showResult(success: false, message: "No text found")
            return
        }

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier,
                                  options: nil) { [weak self] data, error in
                    DispatchQueue.main.async {
                        if let text = data as? String {
                            self?.processSMS(text)
                        } else {
                            self?.showResult(success: false, message: "Could not read text")
                        }
                    }
                }
                return
            }
        }
        showResult(success: false, message: "No plain text found")
    }

    // Step 2: Parse SMS and save to App Group
    private func processSMS(_ text: String) {
        guard let transaction = SMSParser.parse(text) else {
            showResult(success: false,
                       message: "Not a bank transaction SMS.\nTry copying a debit/credit message.")
            return
        }

        let dto = TransactionDTO(from: transaction)
             SharedDataManager.savePendingTransaction(dto)

        showResult(
            success: true,
            message: "₹\(Int(transaction.amount)) from \(transaction.merchant) saved!"
        )
    }

    // Step 3: Show SwiftUI result view
    private func showResult(success: Bool, message: String) {
        let resultView = ShareResultView(
            success: success,
            message: message
        ) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }

        let host = UIHostingController(rootView: resultView)
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        host.didMove(toParent: self)
    }
}
