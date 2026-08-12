import SwiftUI

struct SettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        @Bindable var bVM = viewModel

        List {
            PurchaseSection(
                adsRemoved: viewModel.state.adsRemoved,
                priceText: viewModel.state.removeAdsPriceText,
                inFlight: viewModel.state.purchaseInFlight,
                send: handlePurchaseAction
            )

            SyncSection(
                iCloudOn: viewModel.state.iCloudSyncEnabled,
                notificationStatus: viewModel.state.notificationStatus,
                send: handleSyncAction
            )

            AboutSection(
                versionText: viewModel.state.versionText,
                send: handleAboutAction
            )
        }
        .onAppear {
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
        .alert("Setting changed", isPresented: $bVM.state.showRestartNotice) {
            Button("OK") {}
        } message: {
            Text("iCloud sync will take effect the next time you open the app.")
        }
        .alert("Purchase Failed", isPresented: $bVM.state.showPurchaseError) {
            Button("OK") {}
        } message: {
            Text("The purchase couldn't be completed. Please try again later.")
        }
    }

    // MARK: - L1 協調

    private func handlePurchaseAction(_ action: PurchaseSection.Action) {
        switch action {
        case .removeAdsDidTap:
            Task { await viewModel.doAction(.view(.removeAdsDidTap)) }
        case .restoreDidTap:
            Task { await viewModel.doAction(.view(.restoreDidTap)) }
        }
    }

    private func handleSyncAction(_ action: SyncSection.Action) {
        switch action {
        case let .iCloudToggled(isOn):
            Task { await viewModel.doAction(.view(.iCloudSyncToggled(isOn))) }
        case .notificationDidTap:
            Task { await viewModel.doAction(.view(.notificationDidTap)) }
        }
    }

    private func handleAboutAction(_ action: AboutSection.Action) {
        switch action {
        case .privacyPolicyDidTap:
            Task { await viewModel.doAction(.view(.privacyPolicyDidTap)) }
        }
    }
}

// MARK: - L2

private extension SettingsView {
    struct PurchaseSection: View {
        enum Action: Sendable {
            case removeAdsDidTap
            case restoreDidTap
        }

        let adsRemoved: Bool
        let priceText: String
        let inFlight: Bool
        let send: (Action) -> Void

        var body: some View {
            Section {
                if adsRemoved {
                    HStack {
                        Text("Remove Ads")
                        Spacer()
                        Label("Purchased", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .labelStyle(.titleAndIcon)
                    }
                } else {
                    Button {
                        send(.removeAdsDidTap)
                    } label: {
                        HStack {
                            Text("Remove Ads")
                            Spacer()
                            if inFlight {
                                ProgressView()
                            } else if !priceText.isEmpty {
                                Text(priceText).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(inFlight)

                    Button("Restore Purchase") { send(.restoreDidTap) }
                        .disabled(inFlight)
                }
            } footer: {
                Text(adsRemoved ? "Thanks for your support — the home banner ad has been removed." : "A one-time purchase to permanently remove the home banner ad.")
            }
        }
    }

    struct SyncSection: View {
        enum Action: Sendable {
            case iCloudToggled(Bool)
            case notificationDidTap
        }

        let iCloudOn: Bool
        let notificationStatus: NotificationAuthStatus
        let send: (Action) -> Void

        var body: some View {
            Section {
                Toggle("iCloud Sync", isOn: Binding(
                    get: { iCloudOn },
                    set: { send(.iCloudToggled($0)) }
                ))

                Button {
                    send(.notificationDidTap)
                } label: {
                    HStack {
                        Text("Notifications")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("iCloud sync is off by default; when on, your data is backed up to your iCloud. Adjust notification permissions in system Settings.")
            }
        }

        private var notificationStatusText: String {
            switch notificationStatus {
            case .authorized: String(localized: "On")
            case .denied: String(localized: "Off")
            case .notDetermined: String(localized: "Not set")
            }
        }
    }

    struct AboutSection: View {
        enum Action: Sendable {
            case privacyPolicyDidTap
        }

        let versionText: String
        let send: (Action) -> Void

        var body: some View {
            Section {
                Button("Privacy Policy") { send(.privacyPolicyDidTap) }
                HStack {
                    Text("Version")
                    Spacer()
                    Text(versionText)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SettingsView(viewModel: SettingsViewModel(store: StoreManager()))
}
#endif
