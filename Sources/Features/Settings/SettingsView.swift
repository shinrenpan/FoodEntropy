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
        .alert("設定已變更", isPresented: $bVM.state.showRestartNotice) {
            Button("好") {}
        } message: {
            Text("iCloud 同步將於下次開啟 App 後生效。")
        }
        .alert("購買失敗", isPresented: $bVM.state.showPurchaseError) {
            Button("好") {}
        } message: {
            Text("購買未能完成，請稍後再試。")
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
                        Text("移除廣告")
                        Spacer()
                        Label("已購買", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .labelStyle(.titleAndIcon)
                    }
                } else {
                    Button {
                        send(.removeAdsDidTap)
                    } label: {
                        HStack {
                            Text("移除廣告")
                            Spacer()
                            if inFlight {
                                ProgressView()
                            } else if !priceText.isEmpty {
                                Text(priceText).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(inFlight)

                    Button("還原購買") { send(.restoreDidTap) }
                        .disabled(inFlight)
                }
            } footer: {
                Text(adsRemoved ? "感謝支持，首頁廣告已移除。" : "一次性購買，永久移除首頁橫幅廣告。")
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
                Toggle("iCloud 同步", isOn: Binding(
                    get: { iCloudOn },
                    set: { send(.iCloudToggled($0)) }
                ))

                Button {
                    send(.notificationDidTap)
                } label: {
                    HStack {
                        Text("通知")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("iCloud 同步預設關閉；開啟後將備份至你的 iCloud。通知權限請於系統設定調整。")
            }
        }

        private var notificationStatusText: String {
            switch notificationStatus {
            case .authorized: String(localized: "已開啟")
            case .denied: String(localized: "已關閉")
            case .notDetermined: String(localized: "未設定")
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
                Button("隱私權政策") { send(.privacyPolicyDidTap) }
                HStack {
                    Text("版本")
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
