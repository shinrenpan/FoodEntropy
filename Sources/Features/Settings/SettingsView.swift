import SwiftUI

struct SettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        @Bindable var bVM = viewModel

        List {
            PurchaseSection(send: handlePurchaseAction)

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
        .alert("即將推出", isPresented: $bVM.state.showComingSoon) {
            Button("好") {}
        } message: {
            Text("廣告與購買功能上線後開放。")
        }
        .alert("清除歷史統計？", isPresented: $bVM.state.showClearHistoryConfirm) {
            Button("清除", role: .destructive) {
                Task { await viewModel.doAction(.view(.clearHistoryConfirmed)) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("將刪除所有「已使用 / 丟棄」紀錄，此操作無法復原。")
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
        case .clearHistoryDidTap:
            Task { await viewModel.doAction(.view(.clearHistoryDidTap)) }
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

        let send: (Action) -> Void

        var body: some View {
            Section {
                Button("移除廣告") { send(.removeAdsDidTap) }
                Button("還原購買") { send(.restoreDidTap) }
            } footer: {
                Text("廣告功能上線後開放。")
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
            case clearHistoryDidTap
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

            Section {
                Button("清除歷史統計", role: .destructive) { send(.clearHistoryDidTap) }
            } footer: {
                Text("清除所有「已使用 / 丟棄」紀錄，浪費統計將歸零。此操作無法復原。")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SettingsView(viewModel: SettingsViewModel(manager: try! SwiftDataManager(inMemory: true)))
}
#endif
